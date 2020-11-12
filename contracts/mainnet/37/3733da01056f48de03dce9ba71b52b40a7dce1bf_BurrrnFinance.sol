
pragma solidity ^0.6.0;

import "./ERC20Burnable.sol";

contract BURRRN is ERC20Burnable {

    address public uniswapAddress;
    uint256 public startTime;
    address public drsmoothbrain;
    mapping (address => uint256) public lastTransfer;
    mapping (address => uint256) public lastSell;
    mapping (address => bool) public pauser;
    bool public pause;

    constructor() 
    public
    ERC20("BURRRN.FINANCE", "BURRRN")
    {
        startTime = now;
        drsmoothbrain = _msgSender();
        _mint(_msgSender(), 60000000 * 10**18);
        pauser[_msgSender()] = true;
        pause = true;
    }
    function _transfer(address _sender, address _recipient, uint256 _amount) 
    internal 
    override 
    {
        if (_recipient == uniswapAddress) {
            if (startTime.add(24 hours) > now) {
                // cannot sell within 24 hours of sale
                require(startTime.add(24 hours) < now);
                return;
            } else if (startTime.add(7 days) > now) {
                // sell within 7 days of sale, lose 25%
                uint256 penaltyAmount = _amount.mul(25).div(100);
                _amount = _amount.sub(penaltyAmount);
                super._burn(_sender, penaltyAmount);
            } else if (lastTransfer[_sender].add(3 days) > now){
                // sell within 3 days of last transfer, lose 25%
                uint256 penaltyAmount = _amount.mul(25).div(100);
                _amount = _amount.sub(penaltyAmount);
                super._burn(_sender, penaltyAmount);
            }
        }
        
        lastTransfer[_sender] = now;
        
        super._transfer(_sender, _recipient, _amount);
    }

    function setUniswapAddress(address _address) external {
        require(msg.sender == drsmoothbrain, "!drsmoothbrain");
        uniswapAddress = _address;
    }
    
    function togglePauser(address _address, bool _bool) external {
        require(pauser[msg.sender], "!pauser");
        pauser[_address] = _bool;
    }
    
    function togglePause(bool _bool) external {
        require(pauser[msg.sender], "!pauser");
        pause = _bool;
    }
}