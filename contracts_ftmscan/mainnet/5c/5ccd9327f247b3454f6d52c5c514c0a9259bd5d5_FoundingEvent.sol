/**
 *Submitted for verification at FtmScan.com on 2021-11-17
*/

pragma solidity ^0.7.6;
// author: SamPorter1984
interface I{
	function getPair(address t, address t1) external view returns(address pair);
	function createPair(address t, address t1) external returns(address pair);
	function genesis(uint Ftm,address pair,uint gen) external;
	function genesis(uint b) external;
	function genesis(uint b, address p) external;
	function transfer(address to, uint value) external returns(bool);
	function balanceOf(address) external view returns(uint);
	function addLiquidityETH(address token,uint amountTokenDesired,uint amountTokenMin,uint amountETHMin,address to,uint deadline)external payable returns(uint amountToken,uint amountETH,uint liquidity);
}

contract FoundingEvent {
	mapping(address => uint) public deposits;
	address payable private _deployer;
	bool private _lgeOngoing;
	bool private _emergency;
	uint public hardcap;
	uint public genesisBlock;
	uint private _lock;
	address private _letToken;
	address private _treasury;

	function init() external {
		_deployer = msg.sender;
		_letToken=0x7DA2331C522D4EDFAf545d2F5eF61406D9d637A9;
		_treasury=0x6B51c705d1E78DF8f92317130a0FC1DbbF780a5A;
	}

	function startLGE(uint hc) external {
		require(msg.sender == _deployer);
		if(hardcap != 0){
			require(hc<hardcap);
		}
		_lgeOngoing = true;
		hardcap = hc;
	}

	function triggerLaunch() public {
		require(msg.sender == _deployer);
		_createLiquidity();
	}

	function depositFtm() external payable {
		require(_lgeOngoing == true);
		uint amount = msg.value;
		require(amount<=5e20);
		uint deployerShare = amount/20;
		amount -= deployerShare;
		_deployer.transfer(deployerShare);
		deposits[msg.sender] += amount;
		if(address(this).balance>=hardcap||block.number>=22712000){
			_createLiquidity();
		}
	}

	function _createLiquidity() internal {
		genesisBlock = block.number;
		address WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
		address staking = 0x0FaCF0D846892a10b1aea9Ee000d7700992B64f8;
		address factory = 0x152eE697f2E276fA89E96742e9bB9aB1F2E61bE3;
		address router = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;
		address letToken=_letToken;
		address tknFTMLP = I(factory).getPair(letToken,WFTM);
		address treasury=_treasury;
		if (tknFTMLP == address(0)) {
			tknFTMLP=I(factory).createPair(letToken, WFTM);
		}
		uint balance = address(this).balance;
		//** could be required for future mirrors. ftm starting supply must be fixed, for other mirrors it might be fluctuating
		//uint amount;
		//if (hardcap>balance){
		//	amount = 1e23*balance/hardcap;
		//}
		//**
		//I(letToken).approve(address(router), 1e23);//careful, if token contract does not have hardcoded allowance for the router you need this line
		I(router).addLiquidityETH{value: address(this).balance}(letToken,I(letToken).balanceOf(address(this)),0,0,staking,2**256-1);
		I(staking).genesis(balance, tknFTMLP,block.number);
		//I(letToken).transfer(treasury,I(letToken).balanceOf(address(this)));// burn excess to treasury, in case if hardcap is not reached by the end block. for mirror launches
		I(letToken).genesis(block.number,tknFTMLP);
		I(treasury).genesis(block.number);
		delete _lgeOngoing;
	}

	function toggleEmergency() public {
		require(msg.sender==_deployer);
		if(_emergency != true){
			_emergency = true;
			delete _lgeOngoing;
		} else{
			delete _emergency;
		}
	}

	function withdraw() public {
		require(_emergency == true && deposits[msg.sender]>0 && _lock!=1);
		_lock=1;
		payable(msg.sender).transfer(deposits[msg.sender]);
		_lock=0;
	}

//in case of migration
    function addFounderManually(address a) external payable{
    	require(msg.sender == _deployer);
    	uint amount = msg.value;
    	require(amount<=5e20);
    	uint deployerShare = amount/20;
    	amount -= deployerShare;
    	_deployer.transfer(deployerShare);
    	deposits[a]+=amount;
    }
}