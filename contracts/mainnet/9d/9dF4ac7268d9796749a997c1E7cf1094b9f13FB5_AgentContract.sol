pragma solidity ^0.4.0;

contract AgentContract {

    address __owner;
    address target;
    mapping(address => uint256) agent_to_piece_of_10000;
    address [] agents;
    event SendEther(address addr, uint256 amount);

    function AgentContract(address tar_main,address tar1,address tar2,uint256 stake1,uint256 stake2) public {
        __owner = msg.sender;
        agent_to_piece_of_10000[tar1] = stake1;
        agents.push(tar1);
        agent_to_piece_of_10000[tar2] = stake2;
        agents.push(tar2);
        target = tar_main;
    }
    function getTarget() public constant returns (address){
        assert (msg.sender == __owner);
        return target;
    }
    function listAgents() public constant returns (address []){
        assert (msg.sender == __owner);
        return agents;
    }
    function returnBalanseToTarget() public payable {
        assert (msg.sender == __owner);
        if (!target.send(this.balance)){
            __owner.send(this.balance);
        }
    }
    function() payable public {
        uint256 summa = msg.value;
        assert(summa >= 10000);
        uint256 summa_rest = msg.value;
        for (uint i=0; i<agents.length; i++){
            uint256 piece_to_send = agent_to_piece_of_10000[agents[i]];
            uint256 value_to_send = (summa * piece_to_send) / 10000;
            summa_rest = summa_rest - value_to_send;
            if (!agents[i].send(value_to_send)){
                summa_rest = summa_rest + value_to_send;
            }
            else{
              SendEther(agents[i], value_to_send);
            }
        }
        if (!target.send(summa_rest)){
            if (!msg.sender.send(summa_rest)){
                __owner.send(summa_rest);
                SendEther(__owner, summa_rest);
            }
            else{
              SendEther(msg.sender, summa_rest);
            }
        }
        else{
          SendEther(target, summa_rest);
        }
    }
}