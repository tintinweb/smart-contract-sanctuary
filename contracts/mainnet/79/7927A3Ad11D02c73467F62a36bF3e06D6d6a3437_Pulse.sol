// SPDX-License-Identifier: ISC

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./ERC20.sol";

/**
 *
 * @title Pulse ERC20 token
 * @dev This token serves as the base 
 *      token for the Pulse Platform
 *      
 */
contract Pulse is ERC20, Ownable {
    using SafeMath for uint256;
    
    // Transaction Fees
    uint32 public txFee; //eg: 5k => 5%
    uint32 public feeDivisor;  //eg: 100k => 100%
    address public feeReceiver; //address to receive fees from tx

    // Feeless Address Mapping
    mapping(address => bool) public feeless;

    // Events
    event feeReceiverChanged(address Receiver);
    event UpdatedFeelessAddress(address Address, bool Taxable);

    constructor (uint32 _initFee, uint32 _initDivisor, address _initFeeReceiver) public ERC20("PULSEDEFI.LTD", "PULSE") {
        _mint(msg.sender, 1000000000000000000000000); // 1 million

        // set initial state variables
        txFee = _initFee;
        feeDivisor = _initDivisor;
        feeReceiver = _initFeeReceiver;
    }


    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }


    // set the txFee
    function changeFee(uint32 _newTxFee) public onlyOwner {
        txFee = _newTxFee;
    }

    // assign a new fee distributor address
    function changeFeeReceiver(address _receiver) public onlyOwner {
        feeReceiver = _receiver;
        emit feeReceiverChanged(_receiver);
    }

    // enable/disable address to receive fees
    function updateFeelessAddress(address _address, bool _feeless) public onlyOwner {
        feeless[_address] = _feeless;
        emit UpdatedFeelessAddress(_address, _feeless);
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient` after fees
     * on the transaction have been accounted for.
     *
     * Overrides the internal transfer function for ERC20 and implements
     * a tax on transfer such that the tax will be sent to the feeReceiver
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(sender != address(0), "Pulse: transfer from the zero address!");
        require(recipient != address(0), "Pulse: transfer to the zero address!");
        require(amount > 1_000_000, "Pulse: transferring amount is too small!");

        // check fees and update recipeient balance
        (uint256 transferToAmount, uint256 transferToFeeDistributorAmount) = calculateAmountsAfterFee(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(transferToAmount);
        emit Transfer(sender, recipient, transferToAmount);

        // update distributers balance, if applicable
        if(transferToFeeDistributorAmount > 0){
            _balances[feeReceiver] = _balances[feeReceiver].add(transferToFeeDistributorAmount);
            emit Transfer(sender, feeReceiver, transferToFeeDistributorAmount);
        }
    }

    // check fees and return applicable amounts
    function calculateAmountsAfterFee(
        address sender,
        address recipient,
        uint256 amount
    ) private view returns (uint256 transferToAmount, uint256 transferToFeeDistributorAmount) {

        if (feeless[sender] || feeless[recipient]) {
            return (amount, 0);
        }

        uint256 fee = amount.mul(txFee).div(feeDivisor);
        return (amount.sub(fee), fee);
    }
}