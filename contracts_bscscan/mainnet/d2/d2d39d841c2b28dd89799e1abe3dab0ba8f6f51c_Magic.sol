// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import ".//ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./IMagicTransferGate.sol";
import "./IGatedERC20.sol";
import "./IEventGate.sol";


contract Magic is Initializable, ERC20Upgradeable, OwnableUpgradeable
{

    using SafeMathUpgradeable for uint256;

    IMagicTransferGate public transferGate;
    IEventGate public eventGate;
    address public LPAddress; // axBNB <-> Magic SLP


    mapping(address=>bool) IGNORED_ADDRESSES;
    address public magicZapper;
    address public wizardZapper;
    event TransferGateSet(address transferGate, address eventGate);
    event LPAddressSet(address _LPAddress);
    event ZapperSet(address magicZapper, address wizardZapper);

    function initialize()  public initializer  {

        __Ownable_init_unchained();
        __ERC20_init("Magic","MAGIC");

        _mint(msg.sender, 4000000 ether);
        
    }


    function setIgnoredAddressBulk(address[] memory _ignoredAddressBulk, bool ignore)external onlyOwner{
        
        for(uint i=0;i<_ignoredAddressBulk.length;i++){
            address _ignoredAddress = _ignoredAddressBulk[i];
            IGNORED_ADDRESSES[_ignoredAddress] = ignore;
        }
    }

    function setIgnoredAddresses(address _ignoredAddress, bool ignore)external onlyOwner{
        IGNORED_ADDRESSES[_ignoredAddress]=ignore;
    }
    
    function setTransferGates(IMagicTransferGate _transferGate, IEventGate _eventGate) external onlyOwner()
    {
        transferGate = _transferGate;
        eventGate = _eventGate;
        emit TransferGateSet(address(transferGate),address(eventGate));
    }

    function setLPAddress(address _LPAddress) external onlyOwner()
    {
        require(_LPAddress != address(0), "Magic: _LPAddress cannot be zero address");
        LPAddress = _LPAddress;
        emit LPAddressSet(_LPAddress);
    }


    function setZapper(address _magicZapper, address _wizardZapper) external onlyOwner() {
        require(_magicZapper != address(0), "Magic: _magicZapper cannot be zero address");
        require(_wizardZapper != address(0), "Magic: _wizardZapper cannot be zero address");

        magicZapper = _magicZapper;
        wizardZapper = _wizardZapper;   

        emit ZapperSet(magicZapper, wizardZapper);     
    }

 
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override 
    {
        require(sender != address(0), "Magic: transfer from the zero address");
        require(recipient != address(0), "Magic: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        IMagicTransferGate _transferGate = transferGate;
        uint256 remaining = amount;
        _balances[sender] = _balances[sender].sub(amount, "Magic: transfer amount exceeds balance");

        if(sender == magicZapper && recipient != address(eventGate) && recipient != LPAddress && recipient != address(transferGate) && recipient != wizardZapper) 
        {   
            _balances[address(eventGate)] = _balances[address(eventGate)].add(remaining);
            emit Transfer(sender, address(eventGate), remaining);
            eventGate.handleZap(sender, recipient, remaining); // to lock and transfer remaining Magic after zapRates to recipient
        }

        else if(sender == LPAddress && recipient != address(eventGate) && recipient != magicZapper && recipient != wizardZapper)
        {   
            if (address(_transferGate) != address(0)) {
                (uint256 burn, TransferGateTarget[] memory targets) = _transferGate.handleTransfer(msg.sender, sender, recipient, amount);            
                if (burn > 0) {
                    remaining = remaining.sub(burn, "Magic: Burn too much for zapper");
                    _totalSupply = _totalSupply.sub(burn);
                    emit Transfer(sender, address(0), burn);
                }
                for (uint256 x = 0; x < targets.length; ++x) {
                    (address dest, uint256 amt) = (targets[x].destination, targets[x].amount);
                    remaining = remaining.sub(amt, "Magic: Transfer too much for zapper");
                    _balances[dest] = _balances[dest].add(amt);
                    emit Transfer(sender, dest, amt);
                }
            }
            _balances[address(eventGate)] = _balances[address(eventGate)].add(remaining);
            emit Transfer(sender, address(eventGate), remaining);
            eventGate.handleZap(sender, recipient, remaining); // to lock and transfer remaining Magic after zapRates to recipient
        }
        else 
        if(IGNORED_ADDRESSES[recipient]){// || sender == address(eventGate)) {
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        } 
        else
        {
            if (address(_transferGate) != address(0)) {
                (uint256 burn, TransferGateTarget[] memory targets) = _transferGate.handleTransfer(msg.sender, sender, recipient, amount);            
                if (burn > 0) {
                    remaining = remaining.sub(burn, "Magic: Burn too much");
                    _totalSupply = _totalSupply.sub(burn);
                    emit Transfer(sender, address(0), burn);
                }
                for (uint256 x = 0; x < targets.length; ++x) {
                    (address dest, uint256 amt) = (targets[x].destination, targets[x].amount);
                    remaining = remaining.sub(amt, "Magic: Transfer too much");
                    _balances[dest] = _balances[dest].add(amt);
                    emit Transfer(sender, dest, amt);
                }
            }
            _balances[recipient] = _balances[recipient].add(remaining);
            emit Transfer(sender, recipient, remaining);

        }
    }
}