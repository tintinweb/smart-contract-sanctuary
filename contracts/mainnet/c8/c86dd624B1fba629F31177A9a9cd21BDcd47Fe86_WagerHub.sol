/**
 *Submitted for verification at Etherscan.io on 2021-08-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract WagerHub{
	uint constant $ = 1e18;
	Oracle ORACLE = Oracle(0xa5dD37C92aE550de8C01BF90402B14386E78Fd56);
	address address0 = address(0);
	address THIS = address(this);
	mapping(uint => Wager) wagers;
	uint public wagerCount;
	
	address payable pineapples;
	uint genesis;

	constructor(){
		pineapples = payable(msg.sender);
		genesis = block.timestamp;
	}

	struct Wager{
		uint ID;
		string query;
		address asset;
		uint finalizeWagerTime;
		uint cutOffTime;
		uint unresolvedTimeout;
		uint wagerPositions;
		uint totalValue;

		bool finalized;
		bool unresolved;
		bool oracleRequestSent;

		mapping(address => bool) positioned;
		mapping(address => uint) position;
		mapping(address => uint) weight;
		mapping(uint => uint) totalValueInPosition;

		uint requestTicketID;
		uint winningPosition;
		mapping(address => bool) takenReward;
	}

	function viewWager(uint ID, address perspective) public view returns(
		string memory query,
		address asset,
		uint[] memory UINTs,
		bool[] memory BOOLs,
		uint[] memory positionWeights
	){
		Wager storage wager = wagers[ID];

		query = wager.query;
		asset = wager.asset;
		BOOLs = new bool[](5);
		BOOLs[0] = wager.finalized;
		BOOLs[1] = wager.unresolved;
		BOOLs[2] = wager.oracleRequestSent;
		BOOLs[3] = wager.positioned[perspective];
		BOOLs[4] = wager.takenReward[perspective];

		UINTs = new uint[](10);
		UINTs[0] = wager.finalizeWagerTime;
		UINTs[1] = wager.cutOffTime;
		UINTs[2] = wager.unresolvedTimeout;
		UINTs[3] = wager.wagerPositions;
		UINTs[4] = wager.totalValue;
		UINTs[5] = wager.position[perspective];
		UINTs[6] = wager.weight[perspective];
		UINTs[7] = wager.totalValueInPosition[ UINTs[5] ];
		UINTs[8] = wager.requestTicketID;
		UINTs[9] = wager.winningPosition;

		positionWeights = new uint[](8);
		for(uint i; i<wager.wagerPositions; i+=1){ positionWeights[i] = wager.totalValueInPosition[i]; }
	}

	function viewWagers(uint start, uint L, address perspective) public view returns(
		string[] memory QUERYs, //queries
		address[] memory ASSETs, //assets
		uint[] memory UINTs,
		bool[] memory BOOLs,
		uint[] memory positionWeights
	){
		QUERYs = new string[](L);
		ASSETs = new address[](L);
		BOOLs = new bool[](5*L);
		UINTs = new uint[](10*L);
		positionWeights = new uint[](8*L);

		bool[] memory _BOOLs = new bool[](5);
		uint[] memory _UINTs = new uint[](10);
		uint[] memory _positionWeights = new uint[](8);

		uint j;
		for(uint i = start; i<start+L; i+=1){
			( QUERYs[i], ASSETs[i], _UINTs, _BOOLs, _positionWeights ) = viewWager(i , perspective);
			UINTs[0+i*10] = _UINTs[0];
			UINTs[1+i*10] = _UINTs[1];
			UINTs[2+i*10] = _UINTs[2];
			UINTs[3+i*10] = _UINTs[3];
			UINTs[4+i*10] = _UINTs[4];
			UINTs[5+i*10] = _UINTs[5];
			UINTs[6+i*10] = _UINTs[6];
			UINTs[7+i*10] = _UINTs[7];
			UINTs[8+i*10] = _UINTs[8];
			UINTs[9+i*10] = _UINTs[9];
			BOOLs[0+i*5] = _BOOLs[0];
			BOOLs[1+i*5] = _BOOLs[1];
			BOOLs[2+i*5] = _BOOLs[2];
			BOOLs[3+i*5] = _BOOLs[3];
			BOOLs[4+i*5] = _BOOLs[4];
			for(j=0; j<wagers[i].wagerPositions; j+=1){ positionWeights[j+i*8] = _positionWeights[j]; }
		}
	}

	event NewWager(address sender, address asset, string query, uint cutOffTime, uint finalizeWagerTime, uint unresolvedTimeout, uint wagerPositions);
	function newWagering(
		string memory query,
		address asset,
		uint cutOffTime,
		uint finalizeWagerTime,
		uint unresolvedTimeout, 
		uint wagerPositions
	)public returns(uint wagerID){
		address sender = msg.sender;
		require(cutOffTime < finalizeWagerTime && wagerPositions <= 8 && wagerPositions >= 2);

		wagerID = wagerCount;
		Wager storage wager = wagers[wagerCount];
		wagerCount++;

		wager.ID = wagerID;
		wager.query = query;
		wager.asset = asset;

		wager.cutOffTime = cutOffTime;
		wager.finalizeWagerTime = finalizeWagerTime;
		if(unresolvedTimeout > 86400*30){unresolvedTimeout = 86400*30;}
		if(unresolvedTimeout < 14400){unresolvedTimeout = 14400;}
		wager.unresolvedTimeout = unresolvedTimeout;//no more than 30 days
		wager.wagerPositions = wagerPositions;
		emit NewWager(sender, asset, query, cutOffTime, finalizeWagerTime, unresolvedTimeout, wagerPositions);
	}

	event WagerIn(address sender, uint, uint, uint);
	function wagerIn(uint wagerID, uint wagerPosition) public payable{
		require(wagers[wagerID].asset == address0);
		_wagerIn(wagerID, wagerPosition, msg.value);
	}

	function wagerInToken(uint wagerID, uint wagerPosition, uint value) public{
		require(ERC20(wagers[wagerID].asset).transferFrom(msg.sender,THIS,value));
		_wagerIn(wagerID, wagerPosition, value);
	}

	function _wagerIn(uint wagerID, uint wagerPosition, uint value) internal{
		address sender = msg.sender;
		Wager storage wager = wagers[wagerID];
		require(wagerID<wagerCount && block.timestamp < wager.cutOffTime && value > 0);

		if(!wager.positioned[sender]){
			wager.position[sender] = wagerPosition;
			wager.positioned[sender] = true;
		}else{
			wagerPosition = wager.position[sender];
		}

		wager.totalValue += value;
		wager.weight[sender] += value;
		wager.totalValueInPosition[ wagerPosition ] += value;
		emit WagerIn(sender, wagerID, wager.position[sender], value);
	}


	mapping(uint => uint) ticketToWager;
	event SendOracleRequest(string query, uint wagerID, uint requestTicketID);
	event Unresolved(uint);
	function sendOracleRequest(uint wagerID) public payable{
		Wager storage wager = wagers[wagerID];
		require(!wager.finalized && block.timestamp >= wager.finalizeWagerTime);
		if(block.timestamp >= wager.finalizeWagerTime + wager.unresolvedTimeout){
			wager.unresolved = true;
			wager.finalized = true;
			payable(msg.sender).transfer( msg.value );
			emit Unresolved(wagerID);
		}else{
			uint ID = ORACLE.fileRequestTicket{value: msg.value }(1, false);
			ticketToWager[ID] = wager.ID;
			wager.requestTicketID = ID;
			wager.oracleRequestSent = true;
			emit SendOracleRequest(wager.query, wager.ID, ID);
		}
	}

	event FinalizeWager(uint, bool, uint);
	function oracleObjectiveIntFallback(uint ticketID, bool requestRejected, int[] memory intOptions) external{
		Wager storage wager = wagers[ ticketToWager[ticketID] ];

		require( msg.sender == address(ORACLE) && !wager.finalized);
		
		if(!requestRejected ){
			wager.winningPosition = uint( intOptions[0] );
			wager.finalized = true;
			if(wager.totalValueInPosition[wager.winningPosition] == 0){
				wager.unresolved = true;
			}
		}
		
		emit FinalizeWager(ticketToWager[ticketID], requestRejected, wager.winningPosition);
	}

	mapping(uint => address) newOracle;
    event OracleUpdateRequest(address _newOracle, uint otID);
    function oracleUpdateRequest(address _newOracle) public payable{
		uint otID = ORACLE.fileRequestTicket{value:msg.value}(1, true);
        newOracle[otID] = _newOracle;
        emit OracleUpdateRequest(_newOracle, otID);
    }

	event newOracleRejected(address _newOracle, uint indexed ticketID);
    event newOracleAccepted(address _newOracle, uint indexed ticketID);
    function oracleIntFallback(uint ticketID, bool requestRejected, uint numberOfOptions, uint[] memory optionWeights, int[] memory intOptions) external{
        uint optWeight;
        uint positive;
        uint negative;
        require( msg.sender == address(ORACLE) );

        if(!requestRejected){

	        //YES OR NO?
	        for(uint i; i < numberOfOptions; i+=1){
	            optWeight = optionWeights[i];
	            if(intOptions[i]>0){
	                positive += optWeight;
	            }else{
	                negative += optWeight;
	            }
	        }

            address _newOracle = newOracle[ticketID];
            if(positive>negative){
                ORACLE = Oracle(_newOracle);
                emit newOracleAccepted(_newOracle,ticketID);
            }else{
                emit newOracleRejected(_newOracle,ticketID);
            }
        }
    }

	event PullMoney(address, uint, uint);
	function pullMoney(uint wagerID) public{
		address payable sender = payable(msg.sender);
		Wager storage wager = wagers[wagerID];
		require(wager.finalized && !wager.takenReward[sender] &&/* this last check is technically not necessary*/ wager.positioned[sender]);
		wager.takenReward[sender] = true;
		uint valuePulled;
		if(wager.unresolved){
			valuePulled = wager.weight[sender];
			if(wager.asset == address0){
				sender.transfer( valuePulled );
			}else{
				ERC20(wager.asset).transfer(sender,valuePulled);
			}
			
		}else{
			uint position = wager.winningPosition;
			require(wager.position[sender] == position);
			uint totalValueInPosition =  wager.totalValueInPosition[position];
			valuePulled = wager.totalValue * wager.weight[sender] / totalValueInPosition;

			uint devFee = ( (block.timestamp - genesis) < 86400*30 )?(valuePulled/100):0;
			valuePulled -= devFee;

			if(wager.asset == address0){
				sender.transfer( valuePulled );
				if(devFee>0){
					pineapples.transfer(devFee);
				}
			}else{
				ERC20(wager.asset).transfer(sender, valuePulled);
				if(devFee>0){
					ERC20(wager.asset).transfer(pineapples, devFee);
				}
			}
			
		}
		emit PullMoney(sender, wagerID, valuePulled );
	}

}

abstract contract Oracle{
	function fileRequestTicket( uint8 returnType, bool subjective) public virtual payable returns(uint ticketID);
}

abstract contract ERC20{
    function balanceOf(address _address) public view virtual returns (uint256 balance);
    function transferFrom(address src, address dst, uint amount) public virtual returns (bool);
    function transfer(address _to, uint _value) public virtual returns (bool);
}