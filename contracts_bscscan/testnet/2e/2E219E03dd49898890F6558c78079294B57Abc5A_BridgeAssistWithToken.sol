// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;
import "./Token.sol";
contract BridgeAssist {
    address public owner;
    TokenMintable public TKN;
    bool mintable;
    bool returnable;

    modifier restricted {
        require(msg.sender == owner, "This function is restricted to owner");
        _;
    }
    
    event Collect(address indexed sender, uint256 amount);
    event Dispense(address indexed sender, uint256 amount);
    event TransferOwnership(address indexed previousOwner, address indexed newOwner);

    function collect(address _sender, uint256 _amount) public restricted returns (bool success) {
        require(TKN.allowance(_sender, address(this)) >= _amount, "Amount check failed");
        if (mintable) {
            if (returnable) require(TKN.burnFrom(_sender, _amount), "burnFrom() failure. Make sure that your balance is not lower than the allowance you set");
            else TKN.burnFrom(_sender, _amount);
        } else {
            if (returnable) require(TKN.transferFrom(_sender, address(this), _amount), "transferFrom() failure. Make sure that your balance is not lower than the allowance you set");
            else TKN.transferFrom(_sender, address(this), _amount);
        }
        emit Collect(_sender, _amount);
        return true;
    }

    function dispense(address _sender, uint256 _amount) public restricted returns (bool success) {
        if (mintable) {
            if (returnable) require(TKN.mint(_sender, _amount), "mint() failure. Contact contract owner");
            else TKN.mint(_sender, _amount);
        } else {
            if (returnable) require(TKN.transfer(_sender, _amount), "transfer() failure. Contact contract owner");
            else TKN.transfer(_sender, _amount);
        }
        emit Dispense(_sender, _amount);
        return true;
    }

    function transferOwnership(address _newOwner) public restricted {
        require(_newOwner != address(0), "Invalid address: should not be 0x0");
        emit TransferOwnership(owner, _newOwner);
        owner = _newOwner;
    }
    
    function makeMeNewToken(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply) public restricted {
        TKN = new TokenMintable(_name, _symbol, _decimals, _totalSupply);
    }

    constructor(TokenMintable _TKN, bool _mintable, bool _returnable) {
        TKN = _TKN;
        mintable = _mintable;
        returnable = _returnable;
        owner = msg.sender;
        emit TransferOwnership(address(0), msg.sender);
    }
}

contract BridgeAssistWithToken is BridgeAssist {
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply, bool _mintable) BridgeAssist(TokenMintable(address(0)), _mintable, true) {
        if (_mintable) {
            TKN = new TokenMintable(_name, _symbol, _decimals, _totalSupply);
            TKN.setIssuerRights(address(this), true);
            TKN.transferOwnership(msg.sender);
        }
        else TKN = TokenMintable(address(new Token(_name, _symbol, _decimals, _totalSupply)));
    }
}