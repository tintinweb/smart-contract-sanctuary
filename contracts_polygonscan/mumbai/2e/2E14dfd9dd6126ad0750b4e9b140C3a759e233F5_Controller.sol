// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../library/Owned.sol";
import "../ledger/Ledger.sol";

/**
 * @notice Controller contract for XFUNToken
 */
contract Controller is Owned {
    Ledger public ledger;
    address public token;

    function setToken(address _token) public onlyOwner {
        token = _token;
    }

    function setLedger(address _ledger) public onlyOwner {
        ledger = Ledger(_ledger);
    }

    modifier onlyToken() {
        require(msg.sender == token, "Only token address is allowed.");
        _;
    }

    /**
     * @dev See {Ledger-totalSupply}
     */
    function totalSupply() public view returns (uint256) {
        return ledger.totalSupply();
    }

    /**
     * @dev See {Ledger-balanceOf}
     */
    function balanceOf(address _a) public view onlyToken returns (uint256) {
        return Ledger(ledger).balanceOf(_a);
    }

    /**
     * @dev See {Ledger-allowance}
     */
    function allowance(address _owner, address _spender) public view onlyToken returns (uint256) {
        return ledger.allowance(_owner, _spender);
    }

    /**
     * @dev See {Ledger-transfer}
     */
    function transfer(address _from, address _to, uint256 _value) public onlyToken returns (bool success) {
        return ledger.transfer(_from, _to, _value);
    }

    /**
     * @dev See {Ledger-transferFrom}
     */
    function transferFrom(address _spender, address _from, address _to, uint256 _value) public onlyToken returns (bool success) {
        return ledger.transferFrom(_spender, _from, _to, _value);
    }

    /**
     * @dev See {Ledger-approve}
     */
    function approve(address _owner, address _spender, uint256 _value) public onlyToken returns (bool success) {
        return ledger.approve(_owner, _spender, _value);
    }

    /**
     * @dev See {Ledger-increaseApproval}
     */
    function increaseApproval (address _owner, address _spender, uint256 _addedValue) public onlyToken returns (bool success) {
        return ledger.increaseApproval(_owner, _spender, _addedValue);
    }

    /**
     * @dev See {Ledger-decreaseApproval}
     */
    function decreaseApproval (address _owner, address _spender, uint256 _subtractedValue) public onlyToken returns (bool success) {
        return ledger.decreaseApproval(_owner, _spender, _subtractedValue);
    }

    /**
     * @dev See {Ledger-burn}
     */
    function burn(address _owner, uint256 _amount) public onlyToken {
        ledger.burn(_owner, _amount);
    }

    /**
     * @dev See {Ledger-mint}
     */
    function mint(address _account, uint256 _amount) public onlyToken {
        ledger.mint(_account, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../library/Owned.sol";

/**
 * @notice Ledger contract for XFUN Token
 */
contract Ledger is Owned {

    address public controller;

    mapping(address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    uint256 public totalSupply;

    function setController(address _controller) public onlyOwner {
        controller = _controller;
    }

    modifier onlyController() {
        require(msg.sender == controller, "Only controller is allowed");
        _;
    }

    /**
     * @notice Transfer function for XFUN Token
     * @param _from Sender address to Transfer
     * @param _to Recipient address
     * @param _value Transfer Amount
     * @dev Only Controller can call this function
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address _from, address _to, uint256 _value) public onlyController returns (bool success) {
        require(_to != address(0x0), "Recipient address should be valid address");
        require(balanceOf[_from] >= _value, "Sender balance should not be less than transfer amount");

        balanceOf[_from] = balanceOf[_from] - _value;
        balanceOf[_to] = balanceOf[_to] + _value;
        return true;
    }

    /**
     * @notice TransferFrom function for XFUN Token
     * @param _spender Address of Contract or Account which performs transaction
     * @param _from Sender Address
     * @param _to Recipient Address
     * @param _value Amount to Transfer
     * @dev Only Controller can call this function
     *
     * Requirements:
     *
     * - `_from` and `_to` cannot be the zero address.
     * - `_from` must have a balance of at least `_value`.
     * - the caller must have allowance for ``_from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address _spender, address _from, address _to, uint256 _value) public onlyController returns (bool success) {
        require(_from != address(0) && _to != address(0), "XFUN: transferfrom with unvalid address");

        require(balanceOf[_from] >= _value, "Balance is not sufficient");
        require(allowance[_from][_spender] >= _value, "Approved amount is not sufficient");

        balanceOf[_to] = balanceOf[_to] + _value;
        balanceOf[_from] = balanceOf[_from] - _value;
        allowance[_from][_spender] = allowance[_from][_spender] - _value;
        return true;
    }

    /**
     * @notice Approve function XFUN Token
     * @param _owner The owner of XFUN Token
     * @param _spender Spender which can be allowed by owner
     * @param _value Approve Amount
     * @dev Only Controller can call this function
    * Requirements:
     *
     * - `_owner` cannot be the zero address.
     * - `_spender` cannot be the zero address.
     */
    function approve(address _owner, address _spender, uint256 _value) public onlyController returns (bool success) {
        //require user to set to zero before resetting to nonzero
        require(_owner != address(0x0), "XFUN: approve from the zero address");
        require(_spender != address(0x0), "XFUN: approve to the zero address");
        require(allowance[_owner][_spender] == 0, "Approved amount not be zero");

        allowance[_owner][_spender] = _value;
        return true;
    }

    function increaseApproval (address _owner, address _spender, uint256 _addedValue) public onlyController returns (bool success) {
        require(_owner != address(0x0), "XFUN: approve from the zero address");
        require(_spender != address(0x0), "XFUN: approve to the zero address");

        uint256 oldValue = allowance[_owner][_spender];
        allowance[_owner][_spender] = oldValue + _addedValue;
        return true;
    }

    function decreaseApproval (address _owner, address _spender, uint256 _subtractedValue) public onlyController returns (bool success) {
        require(_owner != address(0x0), "XFUN: approve from the zero address");
        require(_spender != address(0x0), "XFUN: approve to the zero address");

        uint256 oldValue = allowance[_owner][_spender];

        unchecked {
            allowance[_owner][_spender] = oldValue - _subtractedValue;
        }

        return true;
    }  

    function mint(address _account, uint256 _amount) public onlyController {
        require(_account != address(0), "XFUN: mint to the zero address");

        balanceOf[_account] += _amount;
        totalSupply += _amount;
    }

    function burn(address _owner, uint256 _amount) public onlyController {
        require(_owner != address(0), "XFUN: burn from the zero address");
        require(balanceOf[_owner] >= _amount, "XFUN: burn amount exceeds balance");

        balanceOf[_owner] = balanceOf[_owner] - _amount;
        totalSupply = totalSupply - _amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Owned {   

    constructor() {
        owner = msg.sender;
    }

    address private owner;
    address private newOwner;

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }    

    function changeOwner(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}