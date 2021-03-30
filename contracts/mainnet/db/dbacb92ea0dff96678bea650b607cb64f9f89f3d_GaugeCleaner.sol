/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IVoterProxy {
    function withdraw(
        address _gauge,
        address _token,
        uint256 _amount
    ) external returns (uint256);
    function balanceOf(address _gauge) external view returns (uint256);
    function withdrawAll(address _gauge, address _token) external returns (uint256);
    function deposit(address _gauge, address _token) external;
    function harvest(address _gauge) external;
    function lock() external;
    function approveStrategy(address) external;
    function revokeStrategy(address) external;
    function proxy() external returns (address);
}

interface IVoter {
    function setGovernance(address _governance) external;
    function execute(address to, uint value, bytes calldata data) external returns (bool, bytes memory);
}

interface IController {
    function withdraw(address, uint256) external;
    function balanceOf(address) external view returns (uint256);
    function earn(address, uint256) external;
    function want(address) external view returns (address);
    function rewards() external view returns (address);
    function vaults(address) external view returns (address);
    function strategies(address) external view returns (address);
    function approveStrategy(address, address) external;
    function setStrategy(address, address) external;
    function setVault(address, address) external;
}

interface IStrategy {
    function gauge() external returns (address);
}


contract GaugeCleaner {
    address public constant owner = address(0xFEB4acf3df3cDEA7399794D0869ef76A6EfAff52);
    address public constant proxy = address(0x9a165622a744C20E3B2CB443AeD98110a33a231b);
    address public constant mock_proxy = address(0x96Dd07B6c99b22F3f0cB1836aFF8530a98BDe9E3);
    IVoter public constant voter = IVoter(0xF147b8125d2ef93FB6965Db97D6746952a133934);
    IController public constant ctrl = IController(0x9E65Ad11b299CA0Abefc2799dDB6314Ef2d91080);

    constructor() public {}

    function clear(address token) external {
        require(msg.sender == owner, "migrate::!owner");
        address strategy = ctrl.strategies(token);
        address vault = ctrl.vaults(token);
        address gauge = IStrategy(strategy).gauge();

        uint _balance;
        
        _balance = IERC20(gauge).balanceOf(address(voter));
        voter.execute(gauge, 0, abi.encodeWithSignature("withdraw(uint256)", _balance));
        
        _balance = IERC20(token).balanceOf(address(voter));
        voter.execute(token, 0, abi.encodeWithSignature("transfer(address,uint256)", vault, _balance));
        
        require(IERC20(gauge).balanceOf(address(voter)) == 0, "gauge not 0");
        require(IERC20(token).balanceOf(address(voter)) == 0, "voter not 0");
    }

    function setVoterGovernance() external {
        require(msg.sender == owner, "set::!owner");
        voter.setGovernance(owner);
    }

    function voterExecute(address to, uint value, bytes calldata data) external returns (bool success, bytes memory result) {
        require(msg.sender == owner, "vExec::!owner");
        (success, result) = voter.execute(to, value, data);
    }

    function execute(address to, uint value, bytes calldata data) external returns (bool success, bytes memory result) {
        require(msg.sender == owner, "exec::!owner");
        (success, result) = to.call{value: value}(data);
    }
}