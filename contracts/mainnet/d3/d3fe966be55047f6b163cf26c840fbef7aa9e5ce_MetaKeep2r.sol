// SPDX-License-Identifier: MIT


/**
 * KP2R.NETWORK
 * A standard implementation of kp3rv1 protocol
 * Optimized Dapp
 * Scalability
 * Clean & tested code
 */


pragma solidity ^0.5.17;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "add: +");

        return c;
    }
    function add(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "sub: -");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
}

interface IKeep2r {
    function isMinKeeper(address keeper, uint minBond, uint earned, uint age) external returns (bool);
    function receipt(address credit, address keeper, uint amount) external;
    function unbond(address bonding, uint amount) external;
    function withdraw(address bonding) external;
    function bonds(address keeper, address credit) external view returns (uint);
    function unbondings(address keeper, address credit) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function jobs(address job) external view returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface WETH9 {
    function withdraw(uint wad) external;
}

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IKeep2rJob {
    function work() external;
}

contract MetaKeep2r {
    using SafeMath for uint;
    
    modifier upkeep() {
        require(KP2R.isMinKeeper(msg.sender, 100e18, 0, 0), "MetaKeep2r::isKeeper: keeper is not registered");
        uint _before = KP2R.bonds(address(this), address(KP2R));
        _;
        uint _after = KP2R.bonds(address(this), address(KP2R));
        uint _received = _after.sub(_before);
        uint _balance = KP2R.balanceOf(address(this));
        if (_balance < _received) {
            KP2R.receipt(address(KP2R), address(this), _received.sub(_balance));
        }
        _received = _swap(_received);
        msg.sender.transfer(_received);
    }
    
    function task(address job, bytes calldata data) external upkeep {
        require(KP2R.jobs(job), "MetaKeep2r::work: invalid job");
        (bool success,) = job.call.value(0)(data);
        require(success, "MetaKeep2r::work: job failure");
    }
    
    function work(address job) external upkeep {
        require(KP2R.jobs(job), "MetaKeep2r::work: invalid job");
        IKeep2rJob(job).work();
    }
    
    IKeep2r public constant KP2R = IKeep2r(0x9BdE098Be22658d057C3F1F185e3Fd4653E2fbD1);
    WETH9 public constant WETH = WETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IUniswapV2Router public constant UNI = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    
    function unbond() external {
        require(KP2R.unbondings(address(this), address(KP2R)) < now, "MetaKeep2r::unbond: unbonding");
        KP2R.unbond(address(KP2R), KP2R.bonds(address(this), address(KP2R)));
    }
    
    function withdraw() external {
        KP2R.withdraw(address(KP2R));
        KP2R.unbond(address(KP2R), KP2R.bonds(address(this), address(KP2R)));
    }
    
    function() external payable {}
    
    function _swap(uint _amount) internal returns (uint) {
        KP2R.approve(address(UNI), _amount);
        
        address[] memory path = new address[](2);
        path[0] = address(KP2R);
        path[1] = address(WETH);

        uint[] memory amounts = UNI.swapExactTokensForTokens(_amount, uint256(0), path, address(this), now.add(1800));
        WETH.withdraw(amounts[1]);
        return amounts[1];
    }
}