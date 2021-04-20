/**
 *Submitted for verification at Etherscan.io on 2019-05-09
*/

pragma solidity ^0.5.8;

import "./IERC20.sol";
import "./TransferHelper.sol";
import "./SafeMath.sol";
import "./PledgeMining.sol";


contract SunnyStop is Owned {
    IERC20  _tokenA;
    IERC20  _tokenB;
    PledgeMining  _pledgeMining;
    using TransferHelper for address;
    using SafeMath for uint;
//    uint256 periodUnit = 1 minutes;
    uint256 periodUnit = 1 days;


    mapping(address => bool)  public userUse;
    mapping(address => uint256)  public userTokenA;
    mapping(address => uint256)  public userTokenB;

    uint256 public stopTime;
    bool public mining_state;

    struct Record {
        uint256 id;
        uint256 createTime;
        uint256 stopTime;
        uint256 heaven;
        uint256 scale;
        uint256 pledgeAmount;
        uint256 releaseAmount;
        uint256 over; // 1 processing 2 over
    }


    constructor(address tokenA, address tokenB, address payable pledgeMining_) public {
        _tokenA = IERC20(tokenA);
        _tokenB = IERC20(tokenB);
        stopTime = block.timestamp;
        owner = msg.sender;
        _pledgeMining = PledgeMining(pledgeMining_);
        mining_state = true;
    }

    modifier mining {
        require(mining_state, "PLEDGE:STOP_MINING");
        _;
    }


    // 停止挖矿,并从资金池提取WDAO
    function stop_mining(uint256 tokenAAmount, uint256 tokenBAmount) public onlyOwner {
        if (tokenAAmount > 0) {
            require(address(_tokenA).safeTransfer(msg.sender, tokenAAmount), "SAFE_TRANSFER_ERROR");
        }
        if (tokenBAmount > 0) {
            require(address(_tokenB).safeTransfer(msg.sender, tokenBAmount), "SAFE_TRANSFER_ERROR");
        }
        mining_state = false;
    }


    function calcReceiveIncome(Record memory r) internal view returns (uint256){

        uint256 oneTotal = r.pledgeAmount.mul(r.scale).div(uint256(1000));
        uint256 _income = oneTotal.mul(stopTime.sub(r.createTime)).div(r.heaven.mul(periodUnit));
        if (r.stopTime > 0) {
            // total income  =  54ADAO * 12 / 1000 * 周期时间
            // total = amount * scale / 1000 * 周期时间
            uint256 _total = oneTotal
            .mul(r.stopTime.sub(r.createTime).div(r.heaven.mul(periodUnit)));
            if (_income > _total) {
                _income = _total;
            }
        }
        _income = _income.sub(r.releaseAmount);
        // 如果收益大于了平台余额，那么就不给币了
        uint256 _balance = _tokenB.balanceOf(address(this));
        if (_income > 0 && _income > _balance) {
            _income = _balance;
        }
        return (_income);
    }


    function getAmount(address user) public view returns (uint256 token0, uint256 token1){
        if (userUse[user]) {
            return (token0, token1);
        }

        (
        uint256 [4] memory page,
        uint256 [] memory data
        ) = _pledgeMining.getUserRecords(user, 0, 10000);

        uint256 len = page[0];
        uint256 prop_count = page[3];
        for (uint256 i = 0; i < len; i++) {
            Record memory r = Record(
                data[i * prop_count + 0],
                data[i * prop_count + 1],
                data[i * prop_count + 2],
                data[i * prop_count + 3],
                data[i * prop_count + 4],
                data[i * prop_count + 5],
                data[i * prop_count + 6],
                data[i * prop_count + 7]
            );
            if (r.over == uint256(1)) {
                token1 = token1.add(calcReceiveIncome(r));
                token0 = token0.add(r.pledgeAmount);
            }

        }
        return (token0, token1);
    }

    event Withdraw(address indexed user, uint256 indexed token0, uint256 indexed token1);

    function withdraw() public mining {
        require(!userUse[msg.sender], "withdraw Use");
        (uint256 token0, uint256 token1) = getAmount(msg.sender);
        userUse[msg.sender] = true;
        userTokenA[msg.sender] = userTokenA[msg.sender].add(token0);
        userTokenB[msg.sender] = userTokenB[msg.sender].add(token1);
        if (token0 > 0) {
            require(address(_tokenA).safeTransfer(msg.sender, token0), "SAFE_TRANSFER_ERROR TOKEN0");
        }
        if (token1 > 0) {
            require(address(_tokenB).safeTransfer(msg.sender, token1), "SAFE_TRANSFER_ERROR TOKEN1");
        }
        emit Withdraw(msg.sender, token0, token1);
    }
}