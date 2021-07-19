// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import './SafeMath.sol';
import './IERC20.sol';
import './ERC20.sol';
import './Context.sol';
import './Ownable.sol';


contract GuruTOKEN  is ERC20("Guru2", "Guru"), Ownable{


    address public govAddress = 0xCB5a949fF1F8DAA2F41318589De1b6dD4B25EE78;
    address public bonusAddress = 0xCB5a949fF1F8DAA2F41318589De1b6dD4B25EE78;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 public burnRate =  0;
    uint256 public bonusRate = 0;

    uint256 public constant burnRateMax = 10000;
    uint256 public constant burnRateUL = 500;
    uint256 public constant bonusRateMax = 10000;
    uint256 public constant bonusRateUL = 500;

    mapping(address => bool) public whitelist;
    event WhitelistUpdate(address indexed _address, bool statusBefore, bool status);
    event GovAddressUpdate(address govAddressBefore, address govAddress);
    event BonusAddressUpdate(address bonusAddressBefore,address bonusAddress);
    event BonusRateUpdate(uint256 bonusRateBefore,uint256 bonusRate);
    event BurnRateUpdate(uint256 burnRateBefore,uint256 burnRate);

    function mint(address _to, uint256 _amount) external onlyOwner {

         _mint(_to, _amount);

    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {

        if (whitelist[sender] || whitelist[recipient])
         {
            super._transfer(sender, recipient,amount);
            return;
         }

        uint256  burnAmt = amount.mul(burnRate).div(burnRateMax);
        uint256  bonusAmt = amount.mul(bonusRate).div(bonusRateMax);
        amount = amount.sub(burnAmt).sub(bonusAmt);

        super._transfer(sender, recipient, amount);
        if(burnAmt>0)
        {
            super._transfer(sender, burnAddress, burnAmt);
         }
        if(bonusAmt>0)
        {
            super._transfer(sender, bonusAddress, bonusAmt);
        }

    }

    function setGovAddress(address _govAddress) external {
        require(msg.sender == govAddress, "!govAddress");
        address govAddressBefore =  govAddress;
        govAddress = _govAddress;
        emit GovAddressUpdate(govAddressBefore,govAddress);
    }

    function setBonusAddress(address _bonusAddress) external {
        require(msg.sender == govAddress, "!gov");
        require(_bonusAddress != address(0), "zero address");
        address bonusAddressBefore = bonusAddress;
        bonusAddress = _bonusAddress;
        emit BonusAddressUpdate(bonusAddressBefore,bonusAddress);
    }
    function setburnRate(uint256 _burnRate) external {
        require(msg.sender == govAddress, "!govAddress");
        require(burnRate <= burnRateUL, "too high");
        uint256 burnRateBefore = burnRate;
        burnRate = _burnRate;
        emit BurnRateUpdate(burnRateBefore,burnRate);
    }
     function setbonusRate(uint256 _bonusRate) external {
        require(msg.sender == govAddress, "!govAddress");
        require(bonusRate <= bonusRateUL, "too high");
        uint256 bonusRateBefore = bonusRate;
        bonusRate = _bonusRate;
        emit BonusRateUpdate(bonusRateBefore,bonusRate);
    }

    function setWhitelist(address _address,bool status) external {
        require(msg.sender == govAddress, "!govAddress");
        bool statusBefore = whitelist[_address];
        whitelist[_address] = status;
        emit WhitelistUpdate(_address,statusBefore, status);
    }

}