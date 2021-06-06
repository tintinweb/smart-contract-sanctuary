pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

/**
 * @title Staking Token (STK)
 * @author Alberto Cuesta Canada
 * @notice Implements a basic ERC20 staking token with incentive distribution.
 */
contract StakingToken is ERC20, Ownable {
    using SafeMath for uint256;

    /**
     * @notice We usually require to know who are all the stakeholders.
     */
    address[] internal stakeholders;

    /**
     * @notice The stakes for each stakeholder.
     */
    mapping(address => uint256) internal stakes;

    mapping (address => uint256) private _lastDividends;

    uint256 _totalSupply = 1000000000000;
    uint256 totalDividends = 0;
    uint256 unclaimedDividends = 0;

    modifier updateDividend(address investor) {
        uint256 owing = dividendsOwing(investor);

        if (owing > 0) {
            unclaimedDividends = unclaimedDividends.sub(owing);
            _mint(investor, owing);
            //_updateBalance(investor, balanceOf(investor).add(owing));
            _lastDividends[investor] = totalDividends;
        }
     _;
    }

    function dividendsOwing(address investor) internal returns(uint256) {
        uint256 totalUsersBalance = _totalSupply.sub(balanceOf(owner()));
        uint256 newDividends = totalDividends.sub(_lastDividends[investor]);
        
        if (newDividends == 0 || balanceOf(investor) == 0 || totalUsersBalance == 0) {
            return 0;
        }
        
        uint256 owingPercent = balanceOf(investor).mul(100).div(totalUsersBalance);
        return owingPercent.mul(newDividends).div(100);
    }

    function disburse(uint256 amount) onlyOwner public {
        _burn(owner(), amount);
        
        totalDividends = totalDividends.add(amount);
        unclaimedDividends =  unclaimedDividends.add(amount);
    }

    function claimDividend() public {
        address investor = msg.sender;
        uint256 owing = dividendsOwing(investor);

        if (owing > 0) {
            unclaimedDividends = unclaimedDividends.sub(owing);
            _mint(investor, owing);
            _lastDividends[investor] = totalDividends;
        }
    }

    /**
     * @notice The accumulated rewards for each stakeholder.
     */
    mapping(address => uint256) internal rewards;
    
    constructor(address _owner) ERC20("Dividend Elite", "DIVIDEND")
        public
    { 
        _mint(_owner, _totalSupply);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() public view override returns (uint8) {
        return 0;
    }
}