// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;

import "./IERC20.sol";
import "./Reward.sol";
import "./Fee.sol";
import "./Address.sol";
import "./Swap.sol";

contract Dynamix is Reward, IERC20, Fee, Swap {
	using SafeMath for uint256;
	using Address for address;
	
	mapping (address => mapping (address => uint256)) private _allowances;
	
	string public name = 'Dynamix';
    string public symbol = 'DYNA';
    uint8 public decimals = 9;
	
	constructor(uint256 totalSupply, bool testnet) 
		public Reward(totalSupply) Swap(testnet){
			emit Transfer(address(0), _msgSender(), totalSupply);
	}
	
	function totalSupply() public view override returns (uint256) {
        return _tokenSupply;
    }
	
	function balanceOf(address account) public view override returns (uint256)  {
        if (_balances[account].excludedFromReward) 
			return _balances[account].token;
		
        return _rewardToToken(_balances[account].reward);
    }
	
	function transfer(address recipient, uint256 amount) public override returns (bool) {
		 _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount, 0);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
	
	function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
	
	// Internal Transfer, and fee management
	function _transfer(address sender, address recipient, uint256 amount) private {
		uint256 rewardFee = 0;
		
		if(_isBuy(sender)) {
			(uint256 rFee, uint256 tokenToTeam, uint256 tokenToOwner) = _getBuyFee(amount, holders);
			_transfer(sender, teamAddress, tokenToTeam, 0);
			
			// Init timestamp for token hold
			_balances[recipient].timestamp = block.timestamp;
			
			rewardFee = rFee;
			amount = tokenToOwner;
			
			emit Transfer(sender, teamAddress, tokenToTeam);
		}
		
		if(_isSell(recipient)) {
			(uint256 tokenToBuyBack, uint256 tokenToTeam, uint256 tokenToOwner) = _getSellFee(amount, _balances[sender].timestamp);
			_transfer(sender, teamAddress, tokenToTeam, 0);
			_transfer(sender, address(this), tokenToBuyBack, 0);
			
			amount = tokenToOwner;
			
			emit Transfer(sender, teamAddress, tokenToTeam);
			emit Transfer(sender, address(this), tokenToBuyBack);
		}

        amount = _transfer(sender, recipient, amount, rewardFee);
		
		emit Transfer(sender, recipient, amount);
		
		_sellAndBuy();
	}

	bool internal inSellOrBuy;

	modifier lockTheSwap {
        inSellOrBuy = true;
        _;
        inSellOrBuy = false;
    }
	
	// Sell and BuyBack
	function _sellAndBuy() private lockTheSwap {
		if(!inSellOrBuy){
			if(autoSellEnabled){
				
				// Team Balance
				uint256 teamToken = balanceOf(teamAddress);
				if (teamToken >= minimumTokensBeforeSell) {
					_approve(teamAddress, address(uniswapV2Router), teamToken);

					_swapTokensForBNB(teamAddress, teamToken);  // Sell Token for Marketing and Dev costs 
					
					uint256 bnb = address(this).balance;
					uint256 dev = bnb.mul(10).div(100);
					uint256 marketing = bnb.sub(dev);
					
					// transfer 10% of fees to dev team
					devAddress.transfer(dev);
					
					// transfer 90% of fees to marketing team
					marketingAddress.transfer(marketing);
				}

				// Contract Balance
				uint256 contractToken = balanceOf(address(this));
				if (contractToken >= minimumTokensBeforeSell) {
					_approve(address(this), address(uniswapV2Router), contractToken);
					_swapTokensForBNB(address(this), teamToken);  // Sell Token for BuyBack			
				}
			}
			
			if(autoBuyBackEnabled){
				uint256 contractBnb = address(this).balance;
				
				if (contractBnb >= minimumBNBBeforeBuyBack) 
					_approve(address(this), address(uniswapV2Router), contractBnb);
					_buyBackAndBurnToken(contractBnb); // BuyBack and Burn
			}
		}
	}
}