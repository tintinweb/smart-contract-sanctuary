/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

contract Verifier {
    uint256 public constant chainId = 97;
    address public constant verifyingContract = 0x1C56346CD2A2Bf3202F771f50d3D14a367B48070;
    bytes32 public constant salt = 0xf2d857f4a3edcb9b78b4d503bfe733db1e3f6cdc2b7971ee739626c97e86a558;

	struct Order {
        address maker;
        address fromToken;
        address toToken;
        address recipient;
    }
    
    string public constant EIP712_DOMAIN  = "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";
    
    bytes32 public constant EIP712_DOMAIN_TYPEHASH = keccak256(abi.encodePacked(EIP712_DOMAIN));
	bytes32 public constant ORDER_TYPEHASH = keccak256("Order(address maker,address fromToken,address toToken,address recipient)");

    bytes32 public constant DOMAIN_SEPARATOR = keccak256(abi.encode(
        EIP712_DOMAIN_TYPEHASH,
        keccak256("OrderBook"),
        keccak256("1"),
        chainId,
        verifyingContract
    ));

    function hashOrder(Order memory order) public pure returns (bytes32) {
        return keccak256(abi.encode(
                ORDER_TYPEHASH,
                order.maker,
				order.fromToken,
				order.toToken,
				order.recipient
            ));
    }
    
    function hashDomainOrder(Order memory order) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            hashOrder(order)
        ));
    }
    
    function verify() public pure returns (bool) {        
        Order memory order = Order({
            maker: address(0xD3b5134fef18b69e1ddB986338F2F80CD043a1AF),
			fromToken: address(0xbD3079d92db300E4574692F5e4Fc5911a54B8057),
			toToken: address(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd),
			recipient: address(0xD3b5134fef18b69e1ddB986338F2F80CD043a1AF)
        });
        bytes32 sigR = 0x5a3307e6ca70884d7cd33fcfd7e6d404b882e1e449cf1a40d316e918f9003d7f;
        bytes32 sigS = 0x2a5706356cd33b0cf285d03997e27c6455cade023342083440f994e87ef42b64;
        uint8 sigV = 28;
        address signer = 0xD3b5134fef18b69e1ddB986338F2F80CD043a1AF;
    
        return signer == ecrecover(hashDomainOrder(order), sigV, sigR, sigS);
    }
}