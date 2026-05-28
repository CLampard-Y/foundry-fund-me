// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Note: The AggregatorV3Interface might be at a different location than what was in the video!
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

// custom errors
error NotOwner();
error InvalidPriceFeed();
error FundMe_NotEnoughFunds();
error FundMe_CallFailed();

contract FundMe {
    using PriceConverter for uint256;

    event Funded(address indexed funder, uint256 amount);
    event Withdrawn(address indexed owner, uint256 amount);

    mapping(address => uint256) private s_addressToAmountFunded;
    mapping(address => bool) private s_isFunder;
    address[] private s_funders;

    // Could we make this constant?  /* hint: no! We should make it immutable! */
    address private immutable i_owner;
    // immutable is a constant variable that cannot be changed
    // Once it is set, it cannot be changed
    AggregatorV3Interface private immutable i_priceFeed;
    // Minimun amount of USD to fund is 5 USD
    uint256 private constant MINIMUM_USD = 5 * 1e18;

    constructor(address priceFeed) {
        if (priceFeed == address(0)) {
            revert InvalidPriceFeed();
        }
        i_owner = msg.sender;
        i_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        if (msg.value.getConversionRate(i_priceFeed) < MINIMUM_USD) {
            revert FundMe_NotEnoughFunds();
        }
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        // will lead to repeated push
        //s_funders.push(msg.sender);
        if (!s_isFunder[msg.sender]) {
            s_funders.push(msg.sender);
            s_isFunder[msg.sender] = true;
        }
        s_addressToAmountFunded[msg.sender] += msg.value;

        emit Funded(msg.sender, msg.value);
    }

    function getVersion() public view returns (uint256) {
        return i_priceFeed.version();
    }

    modifier onlyOwner() {
        // require(msg.sender == owner);
        if (msg.sender != i_owner) revert NotOwner();
        _;
    }

    // Old version (more gas)
    /*
    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // // transfer
        // payable(msg.sender).transfer(address(this).balance);

        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // call
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }


    // Explainer from: https://solidity-by-example.org/fallback/
    // Conditon: Ether is sent to contract
    //      is msg.data empty?
    //          /   \
    //         yes  no
    //         /     \
    //    receive()?  fallback()
    //     /   \
    //   yes   no
    //  /        \
    //receive()  fallback()
    */

    // Cheaper version
    function Withdraw() public onlyOwner {
        // key difference: we don't need to read length of array every time
        uint256 fundersLength = s_funders.length;
        for (uint256 funderindex = 0; funderindex < fundersLength; funderindex++) {
            address funder = s_funders[funderindex];
            s_addressToAmountFunded[funder] = 0;
            s_isFunder[funder] = false;
        }
        s_funders = new address[](0);

        uint256 amount = address(this).balance;

        (bool callSuccess,) = payable(msg.sender).call{value: amount}("");
        if (!callSuccess) {
            revert FundMe_CallFailed();
        }

        emit Withdrawn(msg.sender, amount);
    }

    // ?
    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }

    /**
     * Getter Functions
     */
    function getMinimumUsd() public pure returns (uint256) {
        return MINIMUM_USD;
    }

    function getAddressToAmountFunded(address fundingAddress) public view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunderAddressByIndex(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getOwnerAddress() public view returns (address) {
        return i_owner;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return i_priceFeed;
    }
}

// Concepts we didn't cover yet (will cover in later sections)
// 1. Enum
// 2. Events
// 3. Try / Catch
// 4. Function Selector
// 5. abi.encode / decode
// 6. Hash with keccak256
// 7. Yul / Assembly
