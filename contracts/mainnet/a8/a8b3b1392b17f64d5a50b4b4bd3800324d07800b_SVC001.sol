pragma solidity ^0.6.11;

import "ERC20.sol"; // basic ERC20 functionality, including _mint and _burn
import "SafeERC20.sol"; // call ERC20 safely
import "SafeMath.sol";
import "Address.sol";

contract SVC001 is ERC20 {
	using SafeERC20 for IERC20;
	using Address for address;
    using SafeMath for uint256;

    address public governance;
    uint256 constant public LOOP_LIMIT = 200;

    constructor () public ERC20("Stacker.vc VCFund1 Token", "SVC001") {
    	governance = msg.sender;
    	_setupDecimals(8);
	}

	// NOTE: set governance to 0x0 in order to disable minting
	function setGovernance(address _governance) external {
		require(msg.sender == governance, "SVC001: !governance");
		governance = _governance;
	}

	function mint(address _account, uint256 _amount) external {
		require(msg.sender == governance, "SVC001: !governance");
		_mint(_account, _amount);
	}

	function mintMany(address[] calldata _accounts, uint256[] calldata _amounts) external {
		require(msg.sender == governance, "SVC001: !governance");
		require(_accounts.length == _amounts.length, "SVC001: length mismatch");
		require(_accounts.length <= LOOP_LIMIT, "SVC001: length > LOOP_LIMIT");

		for (uint256 i = 0; i < _accounts.length; i++){
			_mint(_accounts[i], _amounts[i]);
		}
	}
}