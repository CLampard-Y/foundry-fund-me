// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    event Funded(address indexed funder, uint256 amount);
    event Withdrawn(address indexed owner, uint256 amount);

    FundMe fundMe;

    address alice = makeAddr("alice");
    uint256 public constant SEND_VALUE = 0.1 ether;
    uint256 public constant STARTING_BALANCE = 10 ether;
    uint160 public constant NUMBER_OF_FUNDERS = 10;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // us -> FundMeTest -> FundMe
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        // deployFundMe.run() returns FundMe
        fundMe = deployFundMe.run();
        vm.deal(alice, STARTING_BALANCE);
    }

    function testConstructorRevertsIfPriceFeedIsZeroAddress() public {
        vm.expectRevert(FundMe.FundMe__InvalidPriceFeed.selector);
        new FundMe(address(0));
    }

    modifier funded() {
        vm.prank(alice);
        fundMe.fund{value: SEND_VALUE}();

        // If ture, it means alice's transaction was successful
        assert(address(fundMe).balance > 0);
        _;
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(FundMe.FundMe__NotEnoughFunds.selector);
        fundMe.fund{value: 1}();
    }

    function testFundEmitFundedEvent() public {
        vm.expectEmit(true, false, false, true, address(fundMe));
        emit Funded(alice, SEND_VALUE);

        vm.prank(alice);
        fundMe.fund{value: SEND_VALUE}();
    }

    function testWithdrawEmitWithdrawnEvent() public funded {
        address owner = fundMe.getOwnerAddress();
        uint256 amount = address(fundMe).balance;

        vm.expectEmit(true, false, false, true, address(fundMe));
        emit Withdrawn(owner, amount);

        vm.prank(owner);
        fundMe.withdraw();
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.getMinimumUsd(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOwnerAddress(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();

        if (block.chainid == 1) {
            assertEq(version, 6);
        } else {
            assertEq(version, 4);
        }
    }

    function testFundUpdatesFundDataStructure() public {
        vm.prank(alice);
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAmountFundedByAddress(alice);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testSameFunderIsOnlyAddedOnce() public {
        vm.startPrank(alice);
        fundMe.fund{value: SEND_VALUE}();
        fundMe.fund{value: SEND_VALUE}();
        vm.stopPrank();

        assertEq(fundMe.getFundersLength(), 1);
        assertEq(fundMe.getFunderAddressByIndex(0), alice);
    }

    function testSameFunderAmountStillAccumulates() public {
        vm.startPrank(alice);
        fundMe.fund{value: SEND_VALUE}();
        fundMe.fund{value: SEND_VALUE}();
        vm.stopPrank();

        assertEq(fundMe.getAmountFundedByAddress(alice), 2 * SEND_VALUE);
    }

    function testWithdrawResetsFunderAmount() public funded {
        vm.prank(fundMe.getOwnerAddress());
        fundMe.withdraw();

        assertEq(fundMe.getAmountFundedByAddress(alice), 0);
    }

    function testFunderCanBeAddedAgainAfterWithdraw() public funded {
        vm.prank(fundMe.getOwnerAddress());
        fundMe.withdraw();

        vm.prank(alice);
        fundMe.fund{value: SEND_VALUE}();

        assertEq(fundMe.getFundersLength(), 1);
        assertEq(fundMe.getFunderAddressByIndex(0), alice);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.startPrank(alice);
        fundMe.fund{value: SEND_VALUE}();
        vm.stopPrank();

        address funder = fundMe.getFunderAddressByIndex(0);
        assertEq(funder, alice);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        /*
        OLD VERSION WITHOUT modifier funded()
        vm.prank(alice);
        fundMe.fund{value: SEND_VALUE}();

        vm.expectRevert();
        vm.prank(alice);
        fundMe.withdraw();
        */

        // NEW VERSION WITH modifier funded()
        vm.expectRevert(FundMe.FundMe__NotOwner.selector);
        vm.prank(alice);
        fundMe.withdraw();
    }

    // Single funder
    function testWithdrawFromASingleFunder() public funded {
        // Arrange
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwnerAddress().balance;

        // Act
        vm.startPrank(fundMe.getOwnerAddress());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert
        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwnerAddress().balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }

    // Multiple funders
    function testWithdrawFromMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = NUMBER_OF_FUNDERS;
        // We start with 1 because we already funded alice
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders + startingFunderIndex; i++) {
            // we get hoax from stdcheats
            // Equals to:
            //     vm.prank(address(i));
            //     fundMe.fund{value: SEND_VALUE}();
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwnerAddress().balance;

        // Act
        vm.startPrank(fundMe.getOwnerAddress());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwnerAddress().balance);
        assert((numberOfFunders + 1) * SEND_VALUE == fundMe.getOwnerAddress().balance - startingOwnerBalance);
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        uint160 numberOfFunders = NUMBER_OF_FUNDERS;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders + startingFunderIndex; i++) {
            // we get hoax from stdcheats
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwnerAddress().balance;

        vm.startPrank(fundMe.getOwnerAddress());
        fundMe.withdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwnerAddress().balance);
        assert((numberOfFunders + 1) * SEND_VALUE == fundMe.getOwnerAddress().balance - startingOwnerBalance);
    }

    function testPrintStorageData() public view {
        for (uint256 i = 0; i < 3; i++) {
            bytes32 value = vm.load(address(fundMe), bytes32(i));
            console.log("Value at location", i, ":");
            console.logBytes32(value);
        }
        console.log("PriceFeed address:", address(fundMe.getPriceFeed()));
    }

    // Test receive() & fallback() functions
    function testReceiveFundsContract() public {
        vm.prank(alice);
        (bool success,) = payable(address(fundMe)).call{value: SEND_VALUE}("");

        assertTrue(success);
        assertEq(fundMe.getAmountFundedByAddress(alice), SEND_VALUE);
        assertEq(address(fundMe).balance, SEND_VALUE);
    }

    function testFallbackFundsContract() public {
        vm.prank(alice);
        (bool success,) = payable(address(fundMe)).call{value: SEND_VALUE}("some calldata");

        assertTrue(success);
        assertEq(fundMe.getAmountFundedByAddress(alice), SEND_VALUE);
        //assertEq(fundMe.getOwnerAddress().balance, SEND_VALUE);
        assertEq(address(fundMe).balance, SEND_VALUE);
    }

    function testReceiveFailsWithoutEnoughEth() public {
        vm.prank(alice);
        (bool success,) = payable(address(fundMe)).call{value: 1}("");

        assertFalse(success);
    }

    function testFallbackFailsWithoutEnoughEth() public {
        vm.prank(alice);
        (bool success,) = payable(address(fundMe)).call{value: 1}("some calldata");

        assertFalse(success);
    }
}
