// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

// Why is this a library and not abstract?
// Why not an interface?
library PriceConverter {
    error PriceConverter__InvalidPrice();
    error PriceConverter__StalePrice();

    uint256 private constant STALE_PRICE_TIMEOUT = 3 hours;
    uint8 private constant TARGET_DECIMALS = 18;

    // We could make this public, but then we'd have to deploy it
    // Read ETH/USD price from Chainlink price feed
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        // Sepolia ETH / USD Address
        // https://docs.chain.link/data-feeds/price-feeds/addresses

        // latestRoundData() will return multiple values:
        /*
            (
                uint80 roundId,
                uint256 answer,
                uint256 startedAt,
                uint256 updatedAt,
                uint80 answeredInRound
            )
        */
        (, int256 answer,, uint256 updatedAt,) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        //require(answer > 0, "Invalid price");
        if (answer <= 0) revert PriceConverter__InvalidPrice();
        if (updatedAt == 0 || updatedAt > block.timestamp || block.timestamp - updatedAt > STALE_PRICE_TIMEOUT) {
            revert PriceConverter__StalePrice();
        }

        uint8 priceFeedDecimals = priceFeed.decimals();

        return _scalePriceToTargetDecimals(uint256(answer), priceFeedDecimals);
    }

    // 1000000000
    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        // the actual ETH/USD conversion rate, after adjusting the extra 0s.
        return ethAmountInUsd;
    }

    function _scalePriceToTargetDecimals(uint256 price, uint8 priceDecimals) private pure returns (uint256) {
        if (priceDecimals <= TARGET_DECIMALS) {
            return price * 10 ** (TARGET_DECIMALS - priceDecimals);
        }

        return price / 10 ** (priceDecimals - TARGET_DECIMALS);
    }
}
