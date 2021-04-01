pragma solidity ^0.6.6;

import './Ownable.sol';
import './ACOAssetHelper.sol';

contract ACODistributor is Ownable {

    event Claim(bytes32 indexed id, address indexed account, address indexed aco, uint256 amount);
    event WithdrawToken(address indexed token, uint256 amount, address destination);
    event Halt(bool previousHalted, bool newHalted);
	
    address immutable public signer;
    
    address[] public acos;
    mapping(address => uint256) public acosAmount;
    
    bool public halted;
    
    mapping(bytes32 => bool) public claimed;
    
    modifier isValidMessage(bytes32 id, address account, uint256 amount, uint8 v, bytes32 r, bytes32 s) {
		require(signer == ecrecover(
		    keccak256(abi.encodePacked(
	            "\x19Ethereum Signed Message:\n32", 
	            keccak256(abi.encodePacked(address(this), id, account, amount))
            )), v, r, s), "Invalid arguments");
		_;
	}
    
    constructor (address _signer, address[] memory _acos) public {
        super.init();
        
        signer = _signer;
        halted = false;
        
        for (uint256 i = 0; i < _acos.length; ++i) {
            acos.push(_acos[i]);
        }
    }
    
    function withdrawToken(address token, uint256 amount, address destination) onlyOwner external {
        uint256 _balance = ACOAssetHelper._getAssetBalanceOf(token, address(this));
        if (_balance < amount) {
            amount = _balance;
        }
        if (acosAmount[token] > 0) {
            acosAmount[token] = _balance - amount;    
        }
        ACOAssetHelper._transferAsset(token, destination, amount);
        emit WithdrawToken(token, amount, destination);
    }

    function setAcoBalances() onlyOwner external {
        for (uint256 i = 0; i < acos.length; ++i) {
            acosAmount[acos[i]] = ACOAssetHelper._getAssetBalanceOf(acos[i], address(this));
        }
    }

    function setHalt(bool _halted) onlyOwner external {
        emit Halt(halted, _halted);
        halted = _halted;
    }
    
    function acosLength() view external returns(uint256) {
        return acos.length;
    }
    
    function getClaimableAcos(uint256 amount) view external returns(address[] memory _acos, uint256[] memory _amounts) {
        uint256 qty = 0;
        uint256 remaining = amount;
        for (uint256 i = 0; i < acos.length; ++i) {
            address _aco = acos[i];
            uint256 available = acosAmount[_aco];
            if (available > 0) {
                ++qty;
                if (available >= remaining) {
                    break;
                } else {
                    remaining = remaining - available;
                }
            }
        }

        _acos = new address[](qty);
        _amounts = new uint256[](qty);
        
        if (qty > 0) {
            uint256 index = 0;
            remaining = amount;
            for (uint256 i = 0; i < acos.length; ++i) {
                address _aco = acos[i];
                uint256 available = acosAmount[_aco];
                if (available > 0) {
                    _acos[index] = _aco;
                    if (available >= remaining) {
                        _amounts[index] = remaining;
                        break;
                    } else {
                        remaining = remaining - available;
                        _amounts[index] = available;
                    }
                    ++index;
                }
            }
        }
    }
    
    function claim(
        bytes32 id, 
        address account, 
        uint256 amount, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) isValidMessage(id, account, amount, v, r, s) external {
        require(!halted, "Halted");
        require(!claimed[id], "Claimed");
        
        claimed[id] = true;
        _claim(id, account, amount);
    }
    
    function _claim(bytes32 id, address account, uint256 amount) internal {
        for (uint256 i = 0; i < acos.length; ++i) {
            address _aco = acos[i];
            uint256 available = acosAmount[_aco];
            if (available > 0) {
                if (available >= amount) {
                    acosAmount[_aco] = available - amount;
                    ACOAssetHelper._callTransferERC20(_aco, account, amount);
		            emit Claim(id, account, _aco, amount);
                    break;
                } else {
                    amount = amount - available;
                    acosAmount[_aco] = 0;
                    ACOAssetHelper._callTransferERC20(_aco, account, available);
		            emit Claim(id, account, _aco, available);
                }
            }
        }
    }
}