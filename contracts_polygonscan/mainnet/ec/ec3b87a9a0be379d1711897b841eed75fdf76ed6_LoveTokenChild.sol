// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LibGovStorage.sol";
import "./PolygonERC20Storage.sol";

import "./ERC20Votes.sol";


contract LoveTokenChild is ERC20Votes {
    /**
     * @dev Returns the name of the token.
     */
    function name() public pure override returns (string memory) {
        return "Love";
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public pure override returns (string memory) {
        return "LOVE";
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public pure override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return LibGovStorage.governanceStorage().totalSupply;
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param _account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address _account)  public view override returns (uint256) {
        return LibGovStorage.governanceStorage().balances[_account];
    }

    function transfer(address _to, uint256 _value) public override returns (bool) {
        uint96 value = safe96(_value, "Love: value exceeds 96 bits");
        _transfer(msg.sender, _to, value);
        return true;
    }

    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return LibGovStorage.governanceStorage().approved[_owner][_spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param _spender The address of the account which may transfer tokens
     * @param _rawValue The number of tokens that are approved
     * returns success whether or not the approval succeeded
     */
    function approve(address _spender, uint256 _rawValue) public override returns (bool) {
        uint96 value = safe96(_rawValue, "Love: value exceeds 96 bits");
        // LibGovStorage.governanceStorage().approved[msg.sender][_spender] = value;
        // emit Approval(msg.sender, _spender, value);
        _approve(msg.sender, _spender, value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _rawValue
    ) public override returns (bool) {
        uint96 spenderAllowance = LibGovStorage.governanceStorage().approved[_from][msg.sender];
        uint96 value = safe96(_rawValue, "Love: value exceeds 96 bits");

        if (msg.sender != _from && spenderAllowance != type(uint96).max) {
            uint96 newSpenderAllowance = sub96(spenderAllowance, value, "Love:transferFrom: value exceeds spenderAllowance");
            LibGovStorage.governanceStorage().approved[_from][msg.sender] = newSpenderAllowance;
            emit Approval(_from, msg.sender, newSpenderAllowance);
        }

        _transfer(_from, _to, value);
        return true;
    }

    function increaseAllowance(address _spender, uint256 _value) public override returns (bool) {
        uint96 value = safe96(_value, "Love: value exceeds 96 bits");
        uint96 newSpenderAllowance = add96(LibGovStorage.governanceStorage().approved[msg.sender][_spender], value, "Love: overflow");
        require(newSpenderAllowance > LibGovStorage.governanceStorage().approved[msg.sender][_spender] || value == 0, "Integer Overflow");
        LibGovStorage.governanceStorage().approved[msg.sender][_spender] = newSpenderAllowance;
        emit Approval(msg.sender, _spender, newSpenderAllowance);
        return true;
    }

  /**
   * @notice decrease spend amount granted to spender
   * @param _spender address whose allowance to decrease
   * @param _amount quantity by which to decrease allowance
   * @return success status (always true; otherwise function will revert)
   */
    function decreaseAllowance(address _spender, uint256 _amount) public override returns (bool) {
        uint96 amount = safe96(_amount, "Love: value exceeds 96 bits");
        require(_amount <= LibGovStorage.governanceStorage().approved[msg.sender][_spender], "Integer Underflow");
        
        uint96 newSpenderAllowance = sub96(LibGovStorage.governanceStorage().approved[msg.sender][_spender], amount, "Love: Underflow");
        _approve(msg.sender, _spender, newSpenderAllowance);

        return true;
    }

    /**
     * @notice Polygon child chain ERC20 functions deposit and withdraw
     */
    function deposit(address _user, bytes calldata _depositData) external {
        require(msg.sender == LibPolygonStorage.polygonERC20Storage().childChainManagerProxy, "You're not allowed to deposit");
        uint256 rawAmount = abi.decode(_depositData, (uint256));
        uint96 amount = safe96(rawAmount, "Love: exceeds 96 bits");

        // `amount` token getting minted here & equal amount got locked in RootChainManager
        _mint(_user, amount);
    }

    function withdraw(uint256 _rawAmount) external {
        uint96 amount = safe96(_rawAmount, "Love: exceeds 96 bits");
        _burn(msg.sender, amount);
    }

}