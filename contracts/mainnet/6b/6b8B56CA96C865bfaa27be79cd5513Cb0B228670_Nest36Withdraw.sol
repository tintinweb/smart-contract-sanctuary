/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

// 升级合约
contract Nest36Withdraw {

	//==========NHBTC未领取参数
	// NHBTC Owner
	address constant NHBTC_OWNER = 0x3CeeFBbB0e6C60cf64DB9D17B94917D6D78cec05;
	// NHBTC地址
	address constant NHBTC_ADDRESS = 0x1F832091fAf289Ed4f50FE7418cFbD2611225d46;
	// NHBTC未领取数量
	// uint256 constant NHBTC_AMOUNT = 38216800000000000000000;
	

	//==========NN未领取NEST参数
	// NN领取合约地址
	address constant NNREWARDPOOL_ADDRESS = 0xf1A7201749fA81463799383D7D0565B6bfECE757;
	// NN未领取NEST数量
	// uint256 constant NN_NEST_AMOUNT = 3441295249408000000000000;

	//==========挖矿资金参数
	// 矿工0x4FD6CEAc4FF7c5F4d57A4043cbaA1862F227145A私钥出现问题，导致有两笔nest报价单(6886, 6885)不能正常关闭
	// 经其确认，两笔报价单内锁定的60eth和2996558.362758784295450000nest协助其转入到其提供的新地址0xA05684C9e3A1d62a4EBC5a9FFB13030Bbe5e82a8
	// 新矿工地址
	address constant NEW_MINER = 0xA05684C9e3A1d62a4EBC5a9FFB13030Bbe5e82a8;
	// 挖矿ETH资金
	uint256 constant ETH_AMOUNT_MINING = 60000000000000000000;
	// 挖矿NEST资金
	uint256 constant NEST_AMOUNT_MINING = 2996558362758784295450000;

	// NEST地址
	address constant NEST_ADDRESS = 0x04abEdA201850aC0124161F037Efd70c74ddC74C;
	// NEST3.5挖矿合约地址
	address constant NEST_MINING_ADDRESS = 0x243f207F9358cf67243aDe4A8fF3C5235aa7b8f6;
	// 3.5矿池合约地址
	address constant NEST_POOL_ADDRESS = 0xCA208DCfbEF22941D176858A640190C2222C8c8F;

	// 管理员
    address public _owner;
    
    constructor() {
        _owner = msg.sender;
    }

    // 恢复3.5管理员
    function setGov35() public onlyOwner {
        INestPool(NEST_POOL_ADDRESS).setGovernance(_owner);
    }

    function doit() public onlyOwner {
    	INestPool NestPool = INestPool(NEST_POOL_ADDRESS);
    	// 零:设置地址
    	NestPool.setContracts(address(0x0), address(this), address(0x0), address(0x0), address(0x0), address(0x0), address(0x0), address(0x0));

    	// 一:转移挖矿资金
    	// 1_1.更换ETH账本、更换NEST账本
    	NestPool.transferEthInPool(NEST_POOL_ADDRESS, NEW_MINER, ETH_AMOUNT_MINING);
    	NestPool.transferNestInPool(NEST_POOL_ADDRESS, NEW_MINER, NEST_AMOUNT_MINING);
    	// 1_2.给新矿工地址转ETH和NEST
    	NestPool.withdrawEthAndToken(NEW_MINER, ETH_AMOUNT_MINING, NEST_ADDRESS, NEST_AMOUNT_MINING);

    	// 二:转移NN未领取的NEST
    	uint256 NN_NestAmount = NestPool.getMinerNest(NNREWARDPOOL_ADDRESS);
    	// 2_1.更换NEST账本
    	NestPool.transferNestInPool(NNREWARDPOOL_ADDRESS, _owner, NN_NestAmount);
    	// 2_2.给管理员转账NEST
    	NestPool.withdrawToken(_owner, NEST_ADDRESS, NN_NestAmount);

    	// 三:NHBTC转账
    	uint256 NHBTCAmount = NestPool.balanceOfTokenInPool(NHBTC_OWNER, NHBTC_ADDRESS);
    	NestPool.withdrawToken(NHBTC_OWNER, NHBTC_ADDRESS, NHBTCAmount);

    	// 四:恢复地址
    	NestPool.setContracts(address(0x0), NEST_MINING_ADDRESS, address(0x0), address(0x0), address(0x0), address(0x0), address(0x0), address(0x0));

    	// 五:恢复3.5管理员
    	setGov35();
    }

    modifier onlyOwner {
        require(msg.sender == _owner);
        _;
    }

}

// 3.5矿池合约
interface INestPool {
    // 设置管理员
    function setGovernance(address _gov) external;
    // 设置地址
    function setContracts(
            address NestToken, address NestMining, 
            address NestStaking, address NTokenController, 
            address NNToken, address NNRewardPool, 
            address NestQuery, address NestDAO
        ) external;
    // 转移nest账本
    function transferNestInPool(address from, address to, uint256 amount) external;
    // 转移ETH账本
    function transferEthInPool(address from, address to, uint256 amount) external;
    // 给矿工地址转账ETH和NEST
    function withdrawEthAndToken(address miner, uint256 ethAmount, address token, uint256 tokenAmount) external;
    // 转出Token
    function withdrawToken(address miner, address token, uint256 tokenAmount) external;
    // 查询NEST数量
    function getMinerNest(address miner) external view returns (uint256 nestAmount);
    // 查询其他token数量
    function balanceOfTokenInPool(address miner, address token) external view returns (uint256);
}