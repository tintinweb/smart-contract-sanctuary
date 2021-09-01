// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20.sol";
import "Ownable.sol";

contract MampToken is ERC20, Ownable {

	//list of distributed balance of each address to calculate restricted amount, In Wei
	mapping(address => uint256[3]) private distBalances;
    mapping(address => uint256) private AirdropState;
	// total distributed token amount, In Wei
	uint256 public distributed;

	uint256 public PublicofferingTime1 = 1629820800;  
	uint256 public PublicofferingTime2 = 1630425600;  
	uint256 public PublicofferingTime3 = 1630857600;  
	uint256 public PublicofferingTimeend = 1631375999;
	uint256 public approveswitch = 1;
	// max distribute amount per account, In Wei
	uint256 public maxDistAmount;
	// max distribute amount for all, In Wei, 5% of totalSupply
	uint256 public totalMaxDistAmount = 200000000000 * 10 ** 16 * 5;
	//Airdrop 
    uint256 public Airdrop;
    uint256 public AirdropID;
    uint256 public Airdroptotal;
	//constructor
	constructor() ERC20("Mamp Token", "Mamp") Ownable() {
		//mint to contract owner
		//Private placement 3%
		_mint(0xC6148Fde32Df24d046d24Fa38bBA72EBAE0A1f08, 200000000000 * 10 ** 16 * 3);
		//PANCAKESWAP  1%
		_mint(0xC6148Fde32Df24d046d24Fa38bBA72EBAE0A1f08, 200000000000 * 10 ** 16 * 1);
		//Reward pool 29%
		_mint(0xC6148Fde32Df24d046d24Fa38bBA72EBAE0A1f08, 200000000000 * 10 ** 16 * 29);
		//NFT  50%
		_mint(0xC6148Fde32Df24d046d24Fa38bBA72EBAE0A1f08, 200000000000 * 10 ** 16 * 50);
		//team 10%
		_mint(0xC6148Fde32Df24d046d24Fa38bBA72EBAE0A1f08, 200000000000 * 10 ** 16 * 10);
		//team 10%
		_mint(address(this), 200000000000 * 10 ** 16 * 2);
		//todo, if more EOA address need to mint token, add them here
	}

	function distribute(uint256 _amountInWei, address _to) public onlyOwner {

		if(block.timestamp < PublicofferingTime2){
			require(distBalances[_to][0] <= 23529412 * 10 ** 18);
			require(distributed + _amountInWei <= totalMaxDistAmount);
			distributed = distributed + _amountInWei;
			_mint(_to, _amountInWei);
			distBalances[_to][0] = distBalances[_to][0] + _amountInWei;
		}else if(block.timestamp < PublicofferingTime3){
			require(distBalances[_to][1] <= 21052632 * 10 ** 18);
			require(distributed + _amountInWei <= totalMaxDistAmount);
			distributed = distributed + _amountInWei;
			_mint(_to, _amountInWei);
			distBalances[_to][1] = distBalances[_to][1] + _amountInWei;
		}else if(block.timestamp < PublicofferingTimeend){
			require(distBalances[_to][2] <= 9523810 * 10 ** 18);
			require(distributed + _amountInWei <= totalMaxDistAmount);
			distributed = distributed + _amountInWei;
			_mint(_to, _amountInWei);
			distBalances[_to][2] = distBalances[_to][2] + _amountInWei;
		}
	}
	/**
	 *  ERC 20 Standard Token interface transfer function
	 *
	 *  Prevent transfers until freeze period is over.
	 */
	function transfer(address _to, uint256 _value) public override returns (bool) {

		//calculate free amount
		if (block.timestamp < 1644335999) {
			uint _freeAmount = freeAmount(msg.sender);
			if (_freeAmount < _value) {
				return false;
			}
		}
		_transfer(msg.sender, _to, _value);
		return true;
	}

	function freeAmount(address user) private view returns (uint256) {
		if (block.timestamp >= PublicofferingTimeend + 150 days) {
			return balanceOf(user);
		}
		uint[] memory monthDiff = new uint[](3);
		uint[] memory unrestricted = new uint[](3);
		uint256 amount;
		if (block.timestamp < PublicofferingTime1 + 30 days) {    
			monthDiff[0] = 0;
			monthDiff[1] = 0;
			monthDiff[2] = 0;
			unrestricted[0] = distBalances[user][0] / 2 ;
			unrestricted[1] = distBalances[user][1] / 2 ;
			unrestricted[2] = distBalances[user][2] / 2 ;
		} else {
			monthDiff[0] = (block.timestamp - PublicofferingTime1) / 30 days;   
			monthDiff[1] = (block.timestamp - PublicofferingTime2) / 30 days;   
			monthDiff[2] = (block.timestamp - PublicofferingTime3) / 30 days;   
			
			unrestricted[0] = distBalances[user][0] / 2 + distBalances[user][0] * monthDiff[0] / 10;
			unrestricted[1] = distBalances[user][1] / 2 + distBalances[user][1] * monthDiff[1] / 10;
			unrestricted[2] = distBalances[user][2] / 2 + distBalances[user][2] * monthDiff[2] / 10;
		}
		if (unrestricted[0] > distBalances[user][0]) {
			unrestricted[0] = distBalances[user][0];
		}
		if (unrestricted[1] > distBalances[user][1]) {
			unrestricted[1] = distBalances[user][1];
		}
		if (unrestricted[2] > distBalances[user][2]) {
			unrestricted[2] = distBalances[user][2];
		}
		//5) calculate total free amount including those not from distribution
		// wtf? confuse about the algorithm here
		if (unrestricted[0] + (balanceOf(user) - distBalances[user][1] - distBalances[user][2]) < distBalances[user][0] && unrestricted[1] + (balanceOf(user)- distBalances[user][0] - distBalances[user][2])< distBalances[user][1] && unrestricted[2] + (balanceOf(user)- distBalances[user][0] - distBalances[user][1])< distBalances[user][2]) {
			amount = 0;
		} else {
			amount = unrestricted[0] + unrestricted[1] + unrestricted[2] + balanceOf(user) - distBalances[user][0] - distBalances[user][1] - distBalances[user][2];
		}

		return amount;
	}

	function getFreeAmount() public view returns (uint256) {
		uint256 amount = freeAmount(msg.sender);
		return amount;
	}

	function getRestrictedAmount() public view returns (uint256) {
		uint256 amount = balanceOf(msg.sender) - freeAmount(msg.sender);
		return amount;
	}

	/**
	 * ERC 20 Standard Token interface transfer function
	 *
	 * Prevent transfers until freeze period is over.
	 */
	function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
		//same as above. Replace this line with the following if you want to protect against wrapping uints.
		
		if (block.timestamp < 1644335999) {
			uint _freeAmount = freeAmount(_from);
			if (_freeAmount < _value) {
				return false;
			}
		}
		_transfer(_from, _to, _value);
		uint256 currentAllowance = allowance(_from, msg.sender);

		require(currentAllowance >= _value, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(_from, msg.sender, currentAllowance - _value);
        }
        return true;
	}
    function approve(address spender, uint tokens) public override returns (bool success) {
			if (approveswitch  == 1) {
				return false;
		     }
		_approve(msg.sender,spender,tokens);     
        return true;
    }
	function sapproveswitch(uint256 APPswitch) public onlyOwner {
			approveswitch = APPswitch;
    }
    function Airdropextract(address spender,uint tokens) public onlyOwner{
             _transfer(address(this),spender,tokens);
    }
    function Airdropset(uint sAirdrop,uint sAirdropID,uint sAirdroptotal) public onlyOwner {
            AirdropID = sAirdropID;
            Airdrop  = sAirdrop;
            Airdroptotal = sAirdroptotal;
    }
    function AirdropM() public {
        require(AirdropState[msg.sender] != AirdropID, "MaMo:Airdrop Already received");
        require(Airdroptotal > Airdrop, "MaMo:Airdrop It has been collected");
             _transfer(address(this),msg.sender, Airdrop);
            AirdropState[msg.sender] = AirdropID;
            Airdroptotal -= Airdrop;
    }
	
	}