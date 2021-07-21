// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Include.sol";

contract ASAP is PermitERC20UpgradeSafe {
	function __ASAP_init(address mine_, address eco_, address team_, address contribution_, address liqudity_, address public_, address airdrop_) external initializer {
        __Context_init_unchained();
		__ERC20_init_unchained("ChainSwap.com Governance Token", "ASAP");
		__ASAP_init_unchained(mine_, eco_, team_, contribution_, liqudity_, public_, airdrop_);
	}
	
	function __ASAP_init_unchained(address mine_, address eco_, address team_, address contribution_, address liqudity_, address public_, address airdrop_) public initializer {
		_mint(mine_,            50_000_000 * 10 ** uint256(decimals()));
		_mint(eco_,             10_000_000 * 10 ** uint256(decimals()));
		_mint(team_,            10_000_000 * 10 ** uint256(decimals()));
		_mint(contribution_,    20_000_000 * 10 ** uint256(decimals()));
		_mint(liqudity_,         8_000_000 * 10 ** uint256(decimals()));
		_mint(public_,           1_000_000 * 10 ** uint256(decimals()));
		_mint(airdrop_,          1_000_000 * 10 ** uint256(decimals()));
	}
}


contract ASAPING is ERC20UpgradeSafe, Configurable {
    using SafeERC20 for IERC20;
    
    address public  token;
    uint    public  firstTime;
    uint    public  firstRatio;
    uint    public  begin;
    uint    public  end;
    mapping (address => uint) internal _beginBalances;
	
	function __ASAPING_init(address governor_, address token_) public initializer {
		__Governable_init_unchained(governor_);
        __Context_init_unchained();
		__ERC20_init_unchained("ChainSwap.com ASAP locking", "ASAPING");
		//_setupDecimals(18);
	    token = token_;
	}
	
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        if(from != address(0) && to != address(0)) {
            uint beginAmount = amount.mul(_beginBalances[from]).div(_balances[from]);
            _beginBalances[from] = _beginBalances[from].sub(beginAmount);
            _beginBalances[to] = _beginBalances[to].add(beginAmount);
        }else if(to != address(0))                                              // _mint
            _beginBalances[to] = _beginBalances[to].add(amount);
    }
    
	function startUnlock(address recipient, uint _firstTime, uint _firstRatio, uint _begin, uint _end) external governance {
		require(_firstRatio <= 1e18);
		require(_begin <= _end);
		
		_setupDecimals(ERC20UpgradeSafe(token).decimals());
	    _mint(recipient, IERC20(token).balanceOf(address(this)).sub(_totalSupply));

	    firstTime = _firstTime;
	    firstRatio = _firstRatio;
	    begin = _begin;
	    end = _end;
	}
	
    function unlockCapacity(address holder) public view returns (uint) {
        if(now < firstTime)
            return 0;
        return _balances[holder].sub(_beginBalances[holder].mul(uint(1e18).sub(firstRatio)).div(1e18).mul(end.sub(Math.min(Math.max(begin, now), end))).div(end.sub(begin)));
    }
    
    function unlock() public {
        uint amount = unlockCapacity(msg.sender);
        _burn(msg.sender, amount);
        IERC20(token).safeTransfer(msg.sender, amount);
    }
    
    fallback() external {
        unlock();
    }
}