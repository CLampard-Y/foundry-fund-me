// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract HelperConfigTest is Test {
    uint256 private constant SEPOLIA_CHAINID = 11155111;
    uint256 private constant ANVIL_CHAINID = 31337;
    uint256 private constant MAINNET_CHAINID = 1;
    uint256 private constant UNSUPPORTED_CHAINID = 100;

    address private constant SEPOLIA_ETH_USD_PRICE_FEED = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
    address private constant MAINNET_ETH_USD_PRICE_FEED = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    function testRevertsOnUnsupportedChainId() public {
        uint256 unsupportedChainId = UNSUPPORTED_CHAINID;

        vm.chainId(unsupportedChainId);
        vm.expectRevert(
            abi.encodeWithSelector(HelperConfig.HelperConfig__UnsupportedChainId.selector, unsupportedChainId)
        );

        new HelperConfig();
    }

    function testReturnsSepoliaConfigWhenChainIdIsSepolia() public {
        vm.chainId(SEPOLIA_CHAINID);

        HelperConfig helperConfig = new HelperConfig();
        address priceFeed = helperConfig.activeNetworkConfig();

        assertEq(priceFeed, SEPOLIA_ETH_USD_PRICE_FEED);
    }

    function testCreatesAnvilMockWhenChainIdIsAnvil() public {
        vm.chainId(ANVIL_CHAINID);

        HelperConfig helperConfig = new HelperConfig();
        address priceFeed = helperConfig.activeNetworkConfig();

        assertTrue(priceFeed != address(0));
        assertTrue(priceFeed.code.length > 0);
    }

    function testReturnsMainnetConfigWhenChainIdIsMainnet() public {
        vm.chainId(MAINNET_CHAINID);

        HelperConfig helperConfig = new HelperConfig();
        address priceFeed = helperConfig.activeNetworkConfig();

        assertEq(priceFeed, MAINNET_ETH_USD_PRICE_FEED);
    }

    function testAnvilConfigIsReusedAfterFirstCreation() public {
        vm.chainId(ANVIL_CHAINID);

        HelperConfig helperConfig = new HelperConfig();
        address firstPriceFeed = helperConfig.activeNetworkConfig();

        HelperConfig.NetworkConfig memory secondConfig = helperConfig.getOrCreateAnvilEthConfig();

        assertEq(secondConfig.priceFeed, firstPriceFeed);
    }
}
