// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

/// @title FundMe
/// @notice Allows users to fund the contract with ETH.
///         (if the USD value meets a minimum threshold)
/// @dev Use Chainlink-compatible ETH/USD price feed to convert ETH amounts into USD terms.
contract FundMe {
    // custom errors
    error FundMe__NotOwner();
    error FundMe__InvalidPriceFeed();
    error FundMe__NotEnoughFunds();
    error FundMe__CallFailed();

    using PriceConverter for uint256;

    event Funded(address indexed funder, uint256 amount);
    event Withdrawn(address indexed owner, uint256 amount);

    mapping(address => uint256) private s_addressToAmountFunded;
    mapping(address => bool) private s_isFunder;
    address[] private s_funders;

    address private immutable i_owner;
    AggregatorV3Interface private immutable i_priceFeed;
    // Minimun amount of USD to fund is 5 USD
    uint256 private constant MINIMUM_USD = 5 * 1e18;

    /// @notice Initializes contract with the ETH/USD price feed.
    /// @dev The initial deployer becomes the immutable owner. Reverts if the price feed is zero.
    /// @param priceFeed Address of a Chainlink-compatible ETH/USD price feed.
    constructor(address priceFeed) {
        if (priceFeed == address(0)) {
            revert FundMe__InvalidPriceFeed();
        }
        i_owner = msg.sender;
        i_priceFeed = AggregatorV3Interface(priceFeed);
    }
    
    /// @notice Funds the contract with ETH if meets the minimum USD threshold.
    /// @dev Uses configured price feed to validate msg.value. Tracks each unique funder once while accumulating total funded amout.
    /// @dev Reverts with FundMe__NotEnoughFunds if msg.value converts to less than the minimum USD amount.
    /// @dev Emits a Funded on success. 
    function fund() public payable {
        if (msg.value.getConversionRate(i_priceFeed) < MINIMUM_USD) {
            revert FundMe__NotEnoughFunds();
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
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    /// @notice Withdraws the full contract balance to the owner.
    /// @dev Only callable by owner. Resets the funder accounting before transferring ETH.
    /// @dev Uses call to send ETH to owner. Reverts with FundMe__CallFailed if call fails.
    /// @dev Emits a Withdrawn event on success.
    function withdraw() public onlyOwner {
        // don't need to read length of array every time
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
            revert FundMe__CallFailed();
        }

        emit Withdrawn(msg.sender, amount);
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

    /// @notice Handle ETH transfers with unknown calldata and routes them through fund().
    /// @dev Reverts under same conditions as fund(). Non-empty calldata does not bypass funding validation.
    fallback() external payable {
        fund();
    }

    /// @notice Handle plain ETH transfers and routes them through fund().
    /// @dev Reverts under same conditions as fund(), including the minimum USD requirement. 
    receive() external payable {
        fund();
    }

    /**
     * Getter Functions
     */

    /// @notice Returns the minimum funding threshold in USD with 18 decimals.
    function getMinimumUsd() public pure returns (uint256) {
        return MINIMUM_USD;
    }

    /// @notice Returns the total amount of ETH funded by specific address.
    /// @param fundingAddress Address of the funder.
    /// @return Amount of ETH funded by the address, denominated in wei.
    function getAmountFundedByAddress(address fundingAddress) public view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }
    
    /// @notice Returns the address of funder stored at a specific index.
    /// @param index Index in the funders array.
    /// @return Address of the funder at the given index.
    function getFunderAddressByIndex(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    /// @notice Returns the length of the funders array.
    function getFundersLength() public view returns (uint256) {
        return s_funders.length;
    }

    /// @notice Returns the owner address.
    function getOwnerAddress() public view returns (address) {
        return i_owner;
    }

    /// @notice Returns the configured ETH/USD price feed.
    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return i_priceFeed;
    }
}
