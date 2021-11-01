//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "./ERC20Detailed.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./Killable.sol";
import "./IERC20_Bridge_Logic.sol";
import "./Vega_Staking_Bridge.sol";

contract Base_Faucet_Token is ERC20Detailed, Ownable, ERC20, Killable {

    using SafeMath for uint256;
    uint256 _faucet_amount;
    constructor (string memory _name, string memory _symbol, uint8 _decimals, uint256 total_supply_whole_tokens, uint256 faucet_amount) ERC20Detailed(_name, _symbol, _decimals) {
        uint256 to_mint = total_supply_whole_tokens * (10**uint256(_decimals));
        _faucet_amount = faucet_amount;
        _totalSupply = to_mint;
        _balances[address(this)] = to_mint;
        emit Transfer(address(0), address(this), to_mint);
    }

    // user => last faucet
    mapping(address => uint256) last_faucets;
    // mints and transfers _faucet_amount to the sender
    // limited to once per 24 hours
    function faucet() public {
        require(last_faucets[msg.sender] + 86400 <= block.timestamp, "must wait 24 hours between faucet calls");
        last_faucets[msg.sender] = block.timestamp;
        _totalSupply = _totalSupply.add(_faucet_amount);
        _balances[address(msg.sender)] = _balances[address(msg.sender)].add(_faucet_amount);
        emit Transfer(address(0), address(msg.sender), _faucet_amount);
    }

    function issue(address account, uint256 value) public onlyOwner {
        _transfer(address(this), account, value);
    }

    function admin_deposit_single(uint256 amount, address bridge_address,  bytes32 vega_public_key) public onlyOwner {
        _allowances[address(this)][bridge_address] = amount;
        _totalSupply = _totalSupply.add(amount);
        _balances[address(this)] = _balances[address(this)].add(amount);
        emit Transfer(address(0), address(this), amount);

        IERC20_Bridge_Logic(bridge_address).deposit_asset(address(this), amount, vega_public_key);
    }

    function admin_deposit_bulk(uint256 amount, address bridge_address,  bytes32[] memory vega_public_keys) public onlyOwner {
        uint256 final_amt = amount * vega_public_keys.length;
        _allowances[address(this)][bridge_address] = uint256(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        _totalSupply = _totalSupply.add(final_amt);
        _balances[address(this)] = _balances[address(this)].add(final_amt);
        emit Transfer(address(0), address(this), final_amt);
        for(uint8 key_idx = 0; key_idx < vega_public_keys.length; key_idx++){
            IERC20_Bridge_Logic(bridge_address).deposit_asset(address(this), amount, vega_public_keys[key_idx]);
        }
    }

    function admin_stake_bulk(uint256 amount, address staking_bridge_address,  bytes32[] memory vega_public_keys) public onlyOwner {
      uint256 final_amt = amount * vega_public_keys.length;
      _allowances[address(this)][staking_bridge_address] = uint256(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      _totalSupply = _totalSupply.add(final_amt);
      _balances[address(this)] = _balances[address(this)].add(final_amt);
      emit Transfer(address(0), address(this), final_amt);
      for(uint8 key_idx = 0; key_idx < vega_public_keys.length; key_idx++){
          Vega_Staking_Bridge(staking_bridge_address).stake(amount, vega_public_keys[key_idx]);
      }
    }
}