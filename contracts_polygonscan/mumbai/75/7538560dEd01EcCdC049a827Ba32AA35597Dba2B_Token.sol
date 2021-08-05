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

interface IToken {
    function transfer(address _to, uint256 _value) external returns (bool);
    function balanceOf(address owner) external returns(uint256);
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Owned.sol";
import "../interface/IToken.sol";

contract TokenReceivable is Owned {
    event logTokenTransfer(address token, address to, uint256 amount);

    function claimTokens(address _token, address _to) public onlyOwner returns (bool) {
        IToken token = IToken(_token);
        uint256 balance = token.balanceOf(address(this));
        if (token.transfer(_to, balance)) {
            emit logTokenTransfer(_token, _to, balance);
            return true;
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../library/TokenReceivable.sol";
import "../controller/Controller.sol";

/**
 * @notice Token contract for XFUN token
 */
contract Token is TokenReceivable {

    /**
     *  @notice Constant variables for token
     *  @dev name Token Name for XFUN token: `FunFair`
     *  @dev symbol Token Symbol for XFUN token: `XFUN`
     *  @dev decimals Token Decimal for XFUN token: 8
     */

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event LogMint(address indexed owner, uint256 amount);
    event Burn(address indexed from, uint256 amount);

    string public name = "Funtoken";
    uint8 public decimals = 8;
    string public symbol = "XFUN";

    /// @notice Local variable for memo
    string public motd;    

    /// @notice Controller element
    Controller controller;

    /// @notice owner: Owner Address of XFUN token
    address payable owner;

    /// @notice reference to escrow contract for transaction and authorization
    address escrow;

    /// @notice reference to bridge contracts for minting and burning
    mapping(address => bool) minter;

    event Motd(string message);

    /// @notice to implement POS bridge
    address childChainManagerProxy;

    modifier onlyController() {
        require(msg.sender == address(controller), "This user is not registred controller.");
        _;
    }

    modifier onlyEscrow() {
        require(msg.sender == escrow, "This user is not escrow account.");
        _;
    }

    modifier onlyMinters() {
        require(minter[msg.sender] == true, "This user is not registered minter.");
        _;
    }

    /**
     * @notice Lets owner set the controller contract
     * @param _controller address of controller contract
     */
    function setController(address _controller) external onlyOwner {
        controller = Controller(_controller);
    }

    /**
     * @notice Lets owner set the escrow address
     * @param _escrow address of escrow
     */
    function setEscrow(address _escrow) external onlyOwner {
        escrow = _escrow;
    }

    /**
     * @notice Lets owner register the bridge contract
     * @param _minter address of Minter
     * @dev Minter can be bridge contract and owner or the others
     */
    function registerMinter(address _minter) external onlyOwner {
        minter[_minter] = true;
    }

    /**
     * @dev See {Controller-balanceOf}.
     */
    function balanceOf(address _account) public view returns (uint256) {
        return controller.balanceOf(_account);
    }

    /**
     * @dev See {Controller-balanceOf}.
     */
    function totalSupply() public view returns (uint256) {
        return controller.totalSupply();
    }

    /**
     * @dev See {Controller-allowance}.
     */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return controller.allowance(_owner, _spender);
    }

    /**
     * @dev See {Controller-transfer}.
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(
            success = controller.transfer(
                msg.sender,
                _to,
                _value
                )
            );
        emit Transfer(msg.sender, _to, _value);        
    }

    /**
     * @dev See {Controller-transferFrom}.
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
       require(
           success = controller.transferFrom(
               msg.sender,
               _from,
               _to,
               _value
               )
            );        
        emit Transfer(_from, _to, _value);
    }

    /**
     * @dev See {Controller-approve}.
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        //promote safe user behavior
        require(controller.allowance(msg.sender, _spender) == 0, "Allowance not be zero.");

        success = controller.approve(msg.sender, _spender, _value);
        if (success) {
            emit Approval(msg.sender, _spender, _value);
        }
    }

    /**
     * @dev See {Controller-increaseApproval}.
     */
    function increaseApproval (address _spender, uint256 _addedValue) public returns (bool success) {
        success = controller.increaseApproval(msg.sender, _spender, _addedValue);
        if (success) {
            uint256 newval = controller.allowance(msg.sender, _spender);
            emit Approval(msg.sender, _spender, newval);
        }
    }

    /**
     * @dev See {Controller-decreaseApproval}.
     */
    function decreaseApproval (address _spender, uint256 _subtractedValue) public returns (bool success) {
        success = controller.decreaseApproval(msg.sender, _spender, _subtractedValue);
        if (success) {
            uint256 newval = controller.allowance(msg.sender, _spender);
            emit Approval(msg.sender, _spender, newval);
        }
    }

    /**
     * @notice Let controller emits TransferEvent after transfer execution in controller
     * @param _from Sender address to transfer
     * @param _to Receiver address to transfer
     * @param _value Transfer Amount
     * @dev This function is allowed for only Controller
     */
    function controllerTransfer(address _from, address _to, uint256 _value) external onlyController {
        emit Transfer(_from, _to, _value);
    }

    /**
     * @notice Let controller emits Aprrove after Approve execution in controller
     * @param _owner Owner address for Approve
     * @param _spender Spender address for Approve
     * @param _value Approve Amount
     * @dev This function is allowed for only Controller
     */
    function controllerApprove(address _owner, address _spender, uint256 _value) external onlyController {
        emit Approval(_owner, _spender, _value);
    }

    /**
     * @notice Lets escrow store in Escrow
     * @param _from Sender address for Escrow
     * @param _value Amount to store in Escrow
     */
    function escrowFrom(address _from, uint256 _value) external onlyEscrow {
        require( _from != address(0) && _value > 0);
        require( controller.transfer(_from, escrow, _value));
        emit Transfer(_from, escrow, _value);
    }

    /**
     * @notice Lets escrow return to receiver
     * @param _to Receiver address to get the value from Escrow
     * @param _value Return Amount
     * @param _fee Escrow Fee Amount
     */
    function escrowReturn(address _to, uint256 _value, uint256 _fee) external onlyEscrow {
        require(_to != address(0) && _value > 0);
        if(_fee > 0) {
            //Decrease the total supply and escrow balance when _fee is bigger than 0
            require( _fee < controller.totalSupply() && _fee < controller.balanceOf(escrow) );
            controller.burn(escrow, _fee);
        }
        require(controller.transfer(escrow, _to, _value));
        emit Transfer(escrow, _to, _value);
    }

    // multi-approve, multi-transfer

    bool public multilocked;

    modifier notMultilocked {
        assert(!multilocked);
        _;
    }

    //do we want lock permanent? I think so.
    function lockMultis() public onlyOwner {
        multilocked = true;
    }
   
    function setMotd(string memory _m) public onlyOwner {
        motd = _m;
        emit Motd(_m);
    }

    /**
     * @notice Mint Function
     * @param _account Minting Address
     * @param _amount Minting Amount
     * @dev See {Controller - mint}
     */
    function mint(address _account, uint256 _amount) public onlyMinters {
        controller.mint(_account, _amount);
        emit LogMint(_account, _amount);
    }
    
    /**
     * @notice Burn Function
     * @param _amount Burn Amount
     * @dev See {Controller-burn}.
     */
    function burn(uint256 _amount) public {
        controller.burn(msg.sender, _amount);
        emit Burn(msg.sender, _amount);
    }
}