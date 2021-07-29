/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

/**
 * @file faucet.sol
 * @date 17th Apr 2019
 */
 
pragma solidity ^0.5.0;

contract faucet {
	address public me;

	struct requester {
        address requesteraddress;
        uint amount;
    }
    
    requester[] public requesters;

	constructor() public payable {
		me = msg.sender;
	}

	event sent(uint _amountsent);
	event received();

	function receive()
		public
		payable
	{
		emit received();
	}

    function send(address payable _requester, uint _request)
        public
        payable
    {
        uint amountsent = 1e16;
        _request = _request * 1e18;
        
        if (address(this).balance > _request){
            amountsent = _request/1e18;
            _requester.transfer(_request);   
        }
        else{
            amountsent = (address(this).balance)/1e18;
            _requester.transfer(address(this).balance);
        }
        
        requester memory r;
        r.requesteraddress = _requester;
        r.amount = amountsent;
        requesters.push(r);
        emit sent(amountsent);
    }
}