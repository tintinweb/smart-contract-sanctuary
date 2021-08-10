pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./Operators.sol";
import "./BlockchainCutiesERC1155Interface.sol";

contract Proxy20_1155 is ERC20, Operators {

    BlockchainCutiesERC1155Interface public erc1155;

    uint256 public tokenId;
    string public tokenName;
    string public tokenSymbol;
    bool public canSetup = true;
    uint256 totalTokens = 0;

    modifier canBeStoredIn128Bits(uint256 _value) {
        require(_value <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, "ERC20: id overflow");
        _;
    }

    function setup(
        BlockchainCutiesERC1155Interface _erc1155,
        uint256 _tokenId,
        string calldata _tokenSymbol,
        string calldata _tokenName
    ) external onlyOwner canBeStoredIn128Bits(_tokenId) {
        require(canSetup, "Contract already initialized");
        erc1155 = _erc1155;
        tokenId = _tokenId;
        tokenSymbol = _tokenSymbol;
        tokenName = _tokenName;
    }

    function disableSetup() external onlyOwner {
        canSetup = false;
    }

    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string memory) {
        return tokenName;
    }

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory) {
        return tokenSymbol;
    }

    function totalSupply() external view returns (uint) {
        return totalTokens;
    }

    function balanceOf(address tokenOwner) external view returns (uint) {
        return erc1155.balanceOf(tokenOwner, tokenId);
    }

    function allowance(address, address) external view returns (uint) {
        return 0;
    }

    function transfer(address _to, uint _value) external returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        erc1155.proxyTransfer20(_from, _to, tokenId, _value);
    }

    function approve(address, uint) external returns (bool) {
        revert("ERC20: direct approve is not allowed");
    }

    function transferFrom(address _from, address _to, uint _value) external returns (bool) {
        _transfer(_from, _to, _value);
        return true;
    }

    function onTransfer(address _from, address _to, uint256 _value) external {
        require(msg.sender == address(erc1155), "ERC1155-ERC20: Access denied");
        emit Transfer(_from, _to, _value);
        if (_from == address(0x0)) {
            totalTokens += _value;
        }
        if (_to == address(0x0)) {
            totalTokens -= _value;
        }
    }
}