/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

/**
 *Submitted for verification at Etherscan.io on 2020-08-17
*/

// File: contracts/bancor/token/interfaces/IERC20Token.sol

pragma solidity 0.4.26;

/*
    ERC20 Standard Token interface
*/
contract IERC20Token {
    // these functions aren't abstract since the compiler emits automatically generated getter functions as external
    function name() public view returns (string) {this;}
    function symbol() public view returns (string) {this;}
    function decimals() public view returns (uint8) {this;}
    function totalSupply() public view returns (uint256) {this;}
    function balanceOf(address _owner) public view returns (uint256) {_owner; this;}
    function allowance(address _owner, address _spender) public view returns (uint256) {_owner; _spender; this;}

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

// File: contracts/bancor/utility/interfaces/IOwned.sol

pragma solidity 0.4.26;

/*
    Owned contract interface
*/
contract IOwned {
    // this function isn't abstract since the compiler emits automatically generated getter functions as external
    function owner() public view returns (address) {this;}

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

// File: contracts/bancor/utility/Owned.sol

pragma solidity 0.4.26;


/**
  * @dev Provides support and utilities for contract ownership
*/
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    /**
      * @dev triggered when the owner is updated
      *
      * @param _prevOwner previous owner
      * @param _newOwner  new owner
    */
    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

    /**
      * @dev initializes a new Owned instance
    */
    constructor() public {
        owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly {
        _ownerOnly();
        _;
    }

    // error message binary size optimization
    function _ownerOnly() internal view {
        require(msg.sender == owner, "ERR_ACCESS_DENIED");
    }

    /**
      * @dev allows transferring the contract ownership
      * the new owner still needs to accept the transfer
      * can only be called by the contract owner
      *
      * @param _newOwner    new contract owner
    */
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner, "ERR_SAME_OWNER");
        newOwner = _newOwner;
    }

    /**
      * @dev used by a new owner to accept an ownership transfer
    */
    function acceptOwnership() public {
        require(msg.sender == newOwner, "ERR_ACCESS_DENIED");
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// File: contracts/interfaces/IOracle.sol

pragma solidity ^0.4.26;

contract IOracle {
    function getValue() public view returns (uint256);
}

// File: contracts/interfaces/IAggregator.sol

pragma solidity 0.4.26;

contract IAggregator {
    function latestAnswer() public view returns (int256);
}

// File: contracts/Oracle.sol

pragma solidity 0.4.26;





contract Oracle is IOracle, Owned {

    IAggregator public aggregatorBNTUSD;

    constructor(IAggregator _aggregatorBNTUSD) public {
        aggregatorBNTUSD = _aggregatorBNTUSD;
    }

    function updateAggregator(IAggregator _aggregator) public ownerOnly {
        aggregatorBNTUSD = _aggregator;
    }

    function getValue() public view returns (uint256) {
        return uint256(aggregatorBNTUSD.latestAnswer()) / 1e2;
    }

    function transferERC20Token(IERC20Token _token, address _to, uint256 _amount) public ownerOnly {
        _token.transfer(_to, _amount);
    }

}