/**
 *Submitted for verification at Etherscan.io on 2021-11-15
*/

pragma solidity ^0.8.0;

/// @title   Ethereum or Binnance Bridge
/// @author chandrashekhar
/// @notice You can use this contract for transfer token between two blockchain networks
/// @dev All function calls are currently implemented without side effects

interface IToken {
    function mint(address to, uint256 amount) external;

    function burn(address owner, uint256 amount) external;
}

contract Bridge {
    IToken erc20Token;
    event transfer(uint256 indexed nonce, uint256 amount, address sender);

    uint256 public nonce;
    // mapping(address => uint256) public transferNonce;
    address signer;

    mapping(uint256 => bool) public processnonce;

    constructor(address token, address _signer) {
        erc20Token = IToken(token);
        signer = _signer;
    }

    /// @notice Send the amount form one chain to other
    /// @dev the function actually not send any amount it burn when user use this fuction
    /// @param amount The amount parameter is require

    function transferToken(uint256 amount) public {
        // require(sender == msg.sender);
        erc20Token.burn(msg.sender, amount);
        emit transfer(nonce, amount, msg.sender);
        nonce++;
        // transferNonce[msg.sender] = nonce;
    }

    /// @notice Withdraw the amount at other blockchain
    /// @dev the function actually not withdraw any amount it mint the same amount which burn on first chain
    /// @param amount The amount ,nonces, messageHash,v, r, s,signer parameter is require to withdraw the amount

    function withDrawToken(
        uint256 amount,
        uint256 nonces,
        bytes32 messageHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(processnonce[nonces] == false, "This nonce Already process ");
        require(
            ecrecover(messageHash, v, r, s) == signer,
            "The amount or vrs is not correct "
        );
        // require(
        //     transferNonce[msg.sender] == nonces,
        //     "user not match of this nonce"
        // );
        processnonce[nonces] = true;
        erc20Token.mint(msg.sender, amount);
    }
}