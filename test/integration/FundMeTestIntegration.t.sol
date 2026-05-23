// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";
import {FundMe} from "../../src/FundMe.sol";
import {Test} from "forge-std/Test.sol";

contract InteractionsTest is Test {
    FundMe public fundMe;

    uint256 public constant SEND_VALUE = 0.1 ether;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
    }

    function testUserCanFundAndOwnerWithdrawUsingInteractions() public {
        address fundMeAddress = address(fundMe);
        FundFundMe fundFundMe = new FundFundMe();
        fundFundMe.fundFundMe(fundMeAddress);

        assertEq(fundMeAddress.balance, SEND_VALUE);

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(fundMeAddress);

        assertEq(fundMeAddress.balance, 0);
    }
}
