/**
 *Submitted for verification at Etherscan.io on 2019-07-11
*/

pragma solidity ^0.4.25;



/*
 * Hubii Nahmii
 *
 * Compliant with the Hubii Nahmii specification v0.12.
 *
 * Copyright (C) 2017-2018 Hubii AS
 */



/**
 * @title TransferController
 * @notice A base contract to handle transfers of different currency types
 */
contract TransferController {
    //
    // Events
    // -----------------------------------------------------------------------------------------------------------------
    event CurrencyTransferred(address from, address to, uint256 value,
        address currencyCt, uint256 currencyId);

    //
    // Functions
    // -----------------------------------------------------------------------------------------------------------------
    function isFungible()
    public
    view
    returns (bool);

    /// @notice MUST be called with DELEGATECALL
    function receive(address from, address to, uint256 value, address currencyCt, uint256 currencyId)
    public;

    /// @notice MUST be called with DELEGATECALL
    function approve(address to, uint256 value, address currencyCt, uint256 currencyId)
    public;

    /// @notice MUST be called with DELEGATECALL
    function dispatch(address from, address to, uint256 value, address currencyCt, uint256 currencyId)
    public;

    //----------------------------------------

    function getReceiveSignature()
    public
    pure
    returns (bytes4)
    {
        return bytes4(keccak256("receive(address,address,uint256,address,uint256)"));
    }

    function getApproveSignature()
    public
    pure
    returns (bytes4)
    {
        return bytes4(keccak256("approve(address,uint256,address,uint256)"));
    }

    function getDispatchSignature()
    public
    pure
    returns (bytes4)
    {
        return bytes4(keccak256("dispatch(address,address,uint256,address,uint256)"));
    }
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/*
 * Hubii Nahmii
 *
 * Compliant with the Hubii Nahmii specification v0.12.
 *
 * Copyright (C) 2017-2018 Hubii AS
 */






/**
 * @title ERC20TransferController
 * @notice Handles transfers of ERC20 tokens
 */
contract ERC20TransferController is TransferController {
    //
    // Functions
    // -----------------------------------------------------------------------------------------------------------------
    function isFungible()
    public
    view
    returns (bool)
    {
        return true;
    }

    /// @notice MUST be called with DELEGATECALL
    function receive(address from, address to, uint256 amount, address currencyCt, uint256 currencyId)
    public
    {
        require(msg.sender != address(0));
        require(amount > 0);
        require(currencyId == 0);

        require(IERC20(currencyCt).transferFrom(from, to, amount));

        // Emit event
        emit CurrencyTransferred(from, to, amount, currencyCt, currencyId);
    }

    /// @notice MUST be called with DELEGATECALL
    function approve(address to, uint256 amount, address currencyCt, uint256 currencyId)
    public
    {
        require(amount > 0);
        require(currencyId == 0);

        require(IERC20(currencyCt).approve(to, amount));
    }

    /// @notice MUST be called with DELEGATECALL
    function dispatch(address from, address to, uint256 amount, address currencyCt, uint256 currencyId)
    public
    {
        require(amount > 0);
        require(currencyId == 0);

        require(IERC20(currencyCt).approve(from, amount));
        require(IERC20(currencyCt).transferFrom(from, to, amount));

        // Emit event
        emit CurrencyTransferred(from, to, amount, currencyCt, currencyId);
    }
}