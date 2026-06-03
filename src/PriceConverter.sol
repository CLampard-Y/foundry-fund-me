// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

// Why is this a library and not abstract?
// Why not an interface?

/// @title PriceConverter
/// @notice Provides helper functions for converting ETH amounts to USD values.
/// @dev Assumes a Chainlink-compatible feed and validates price positivity and freshness before conversion.
library PriceConverter {
    error PriceConverter__InvalidPrice();
    error PriceConverter__StalePrice();

    uint256 private constant STALE_PRICE_TIMEOUT = 3 hours;
    uint8 private constant TARGET_DECIMALS = 18;

    /// @notice Read the latest ETH/USD price from Chainlink price feed.
    /// @dev Reverts if the price is non-positive, missing, from the future or stale.
    /// @param priceFeed Chainlink-compatible price feed used for the ETH/USD price.
    /// @return ETH/USD price scaled to target decimals (default 18 decimals).
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

        if (updatedAt == 0) revert PriceConverter__StalePrice();

        // Price freshness uses an hour-level timeout, so minor validator timestamp drift
        // does not affect this stale-price security assumption.
        // forge-lint: disable-next-line(block-timestamp)
        if (updatedAt > block.timestamp) revert PriceConverter__StalePrice();

        // Price freshness uses an hour-level timeout, so minor validator timestamp drift
        // does not affect this stale-price security assumption.
        // forge-lint: disable-next-line(block-timestamp)
        if (block.timestamp - updatedAt > STALE_PRICE_TIMEOUT) {
            revert PriceConverter__StalePrice();
        }

        // casting to uint256 is safe because non-positive prices revert above
        // forge-lint: disable-next-line(unsafe-typecast)
        uint256 unsignedAnswer = uint256(answer);

        uint8 priceFeedDecimals = priceFeed.decimals();

        return _scalePriceToTargetDecimals(unsignedAnswer, priceFeedDecimals);
    }

    /// @notice Converts an ETH amount into its USD value using the provided price feed.
    /// @dev The returned USD value uses 18 decimals. Reverts under the same oracle validation rules as getPrice().
    /// @param ethAmount ETH amount denominated in wei.
    /// @param priceFeed Chainlink-compatible ETH/USD price feed.
    /// @return USD value of the ETH amount, scaled to 18 decimals.
    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        // the actual ETH/USD conversion rate, after adjusting the extra 0s.
        return ethAmountInUsd;
    }

    /// @dev Scales a price value from its feed decimals to the library target decimals.
    function _scalePriceToTargetDecimals(uint256 price, uint8 priceDecimals) private pure returns (uint256) {
        if (priceDecimals <= TARGET_DECIMALS) {
            return price * 10 ** (TARGET_DECIMALS - priceDecimals);
        }

        return price / 10 ** (priceDecimals - TARGET_DECIMALS);
    }
}
