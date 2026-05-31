// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {PriceConverter} from "../../src/PriceConverter.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract PriceConverterHarness {
    using PriceConverter for uint256;

    function getPrice(AggregatorV3Interface priceFeed) external view returns (uint256) {
        return PriceConverter.getPrice(priceFeed);
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) external view returns (uint256) {
        return ethAmount.getConversionRate(priceFeed);
    }
}

contract PriceConverterTest is Test {
    PriceConverterHarness harness;
    MockV3Aggregator mockPriceFeed;

    uint8 private constant DECIMALS = 8;
    int256 private constant INITIAL_PRICE = 2000e8;

    function setUp() external {
        mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        harness = new PriceConverterHarness();
    }

    function testGetPriceRevertsIfPriceIsZero() public {
        //mockPriceFeed.updateAnswer(0);
        // More precise mock
        mockPriceFeed.updateRoundData(1, 0, block.timestamp, block.timestamp);

        vm.expectRevert(PriceConverter.PriceConverter__InvalidPrice.selector);
        harness.getPrice(mockPriceFeed);
    }

    function testGetPriceRevertsIfPriceIsNegative() public {
        //mockPriceFeed.updateAnswer(-1);
        // More precise mock
        mockPriceFeed.updateRoundData(1, -1, block.timestamp, block.timestamp);

        vm.expectRevert(PriceConverter.PriceConverter__InvalidPrice.selector);
        harness.getPrice(mockPriceFeed);
    }

    function testGetPriceRevertsIfPriceIsStale() public {
        vm.warp(10 hours);

        uint256 staleUpdatedAt = block.timestamp - 4 hours;
        mockPriceFeed.updateRoundData(1, INITIAL_PRICE, staleUpdatedAt, staleUpdatedAt);

        vm.expectRevert(PriceConverter.PriceConverter__StalePrice.selector);
        harness.getPrice(mockPriceFeed);
    }

    function testGetPriceRevertsIfUpdatedAtIsInFuture() public {
        uint256 futureUpdatedAt = block.timestamp + 1 hours;

        mockPriceFeed.updateRoundData(1, INITIAL_PRICE, futureUpdatedAt, block.timestamp);

        vm.expectRevert(PriceConverter.PriceConverter__StalePrice.selector);
        harness.getPrice(mockPriceFeed);
    }

    function testGetPriceRevertsIfUpdatedAtIsZero() public {
        mockPriceFeed.updateRoundData(1, INITIAL_PRICE, 0, block.timestamp);

        vm.expectRevert(PriceConverter.PriceConverter__StalePrice.selector);
        harness.getPrice(mockPriceFeed);
    }

    function testGetPriceScalesEightDecimalsToEighteenDecimals() public view {
        uint256 price = harness.getPrice(mockPriceFeed);

        assertEq(price, 2000e18);
    }

    // Dont change decimals by updateRoundData
    // decimals is price feed contract-level setting
    // not rounddata-level information
    function testGetPriceScalesSixDecimalsToEighteenDecimals() public {
        MockV3Aggregator sixDecimalFeed = new MockV3Aggregator(6, 2000e6);

        uint256 price = harness.getPrice(sixDecimalFeed);

        assertEq(price, 2000e18);
    }

    function testGetPriceKeepsEighteenDecimals() public {
        MockV3Aggregator eighteenDecimalFeed = new MockV3Aggregator(18, 2000e18);

        uint256 price = harness.getPrice(eighteenDecimalFeed);

        assertEq(price, 2000e18);
    }

    function testGetConversionRateReturnsUsdValue() public view {
        uint256 usdValue = harness.getConversionRate(1 ether, mockPriceFeed);

        assertEq(usdValue, 2000e18);
    }

    function testGetConversionRateWithFractionalEth() public view {
        uint256 usdValue = harness.getConversionRate(0.1 ether, mockPriceFeed);

        assertEq(usdValue, 200e18);
    }
}
