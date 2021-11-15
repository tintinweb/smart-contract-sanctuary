//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function name() external view   returns (string memory);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface IUniswapRouter {
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Interfaces.sol";

contract MultiSig {
    
    IUniswapRouter constant router= IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address immutable WETH;

    address immutable DAI;

    uint private totalPower;

    uint[] private enableTransactions;

    mapping(address => uint) public approvers;

    mapping(address => mapping(uint => bool)) private approvement;

    mapping(uint => EthTransfer) private ethTransfer;

    mapping(uint => TokenTransfer) private tokenTransfer;

    mapping(uint => ApproversEvent) private approversEvent;

    uint counter;

    enum Approve {APPROVE,REJECT}

    event createdEthTransfer(uint id, address to, uint amount, uint asDai,address creater);
    event createdTokenTransfer(uint id,address to,address token,uint amount,address creater);
    event createdVote(uint id,address who,address creater,Approve approve,uint amount);

    struct EthTransfer {
        uint id;
        address payable to;
        uint amount;
        uint amountDai;
        address creater;
        string describe;
        uint approve;
        uint reject;
    }

    struct TokenTransfer {
        uint id;
        address to;
        address tokenAddress;
        uint amount;
        uint amountDai;
        address creater;
        string tokenName;
        string describe;
        uint approve;
        uint reject;
    }

    struct ApproversEvent {
        uint id;
        address who;
        Approve appro;
        address creater;
        uint amount;
        uint approve;
        uint reject;
    }

    constructor(address[] memory _addr, uint[] memory _powers, address _WETH,address _DAI) {
        for (uint256 i = 0; i < _addr.length; i++) {
            approvers[_addr[i]] = _powers[i];
            totalPower += _powers[i];
        }
        WETH = _WETH;
        DAI = _DAI;

    }
    function showEnableTransactions() public view onlyApprovers returns(uint[] memory) {
        return enableTransactions;
    }

    function showEthTransfer(uint _id) public view returns(EthTransfer memory) {
        return ethTransfer[_id];
    } 
    function showTokenTransfer(uint _id) public view returns(TokenTransfer memory) {
        return tokenTransfer[_id];
    }
    function showApproverEvent(uint _id) public view returns(ApproversEvent memory) {
        return approversEvent[_id];
    }

    function createEthTransfer(address payable _to, uint _amount,string memory _describe) external onlyApprovers {
        counter = (counter - (counter % 10)) + 11;
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = DAI;
        uint[] memory dai = router.getAmountsOut(_amount,path);
        ethTransfer[counter] = EthTransfer({
            id: counter,
            to: _to,
            amount: _amount,
            amountDai: dai[1],
            creater: msg.sender,
            describe: _describe,
            approve: 0,
            reject: 0
        });
        enableTransactions.push(counter);
        emit createdEthTransfer(counter,_to,_amount,dai[1],msg.sender);
    }

    function createTokenTransfer(address _to,address _token, uint _amount,string memory _describe) external onlyApprovers {
        counter = (counter - (counter % 10)) + 12;
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = DAI;
        uint[] memory dai = router.getAmountsOut(_amount,path);
        string memory name = IERC20(_token).name();
        tokenTransfer[counter] = TokenTransfer({
            id:counter,
            to:_to,
            amount:_amount,
            amountDai: dai[1],
            creater: msg.sender,
            tokenAddress:_token,
            tokenName:name ,
            describe: _describe,
            approve:0,
            reject:0
        });
        enableTransactions.push(counter);
        emit createdTokenTransfer(counter,_to,_token,_amount,msg.sender);        
    }

    function createrApproverEvent(address _who, Approve _event, uint _amount) external onlyApprovers {
        require(!(uint(_event) == 1 && _amount >approvers[_who]),"haydaaaa");
        counter = (counter - (counter % 10)) + 13;

        approversEvent[counter] = ApproversEvent({
            id: counter,
            who: _who,
            creater: msg.sender,
            appro: _event,
            amount: _amount,
            approve: 0,
            reject: 0
        });
        enableTransactions.push(counter);
        emit createdVote(counter,approversEvent[counter].who,msg.sender,_event,_amount);
    }
    
    function vote(uint _id,Approve _vote) external onlyApprovers {
        require(_id <= counter,"invalid id");
        require(approvement[msg.sender][_id] == false,"already approved");

        uint group = _id % 10;

        uint minVote;

        totalPower % 2 == 0 ? minVote = totalPower / 2 : minVote = (totalPower / 2) + 1;
        if(group == 1){
            EthTransferFunction(_id,_vote,minVote);     
        } else if (group == 2) {
            TokenTransferFunction(_id,_vote,minVote);
        } else if (group == 3) { 
            approveFunction(_id,_vote);       
        }
    }
    function EthTransferFunction(uint _id,Approve _vote,uint minVote) private {
        EthTransfer storage ethT = ethTransfer[_id];

            uint(_vote) == 0 ? ethT.approve += approvers[msg.sender]
            : ethT.reject += approvers[msg.sender];

            approvement[msg.sender][_id] = true;

            if(ethT.approve >=minVote ){

                ethT.to.transfer(ethT.amount);

                deleteFromList(_id);

            } else if(ethT.reject >=minVote){

                deleteFromList(_id);
            } 
    }
    function TokenTransferFunction(uint _id,Approve _vote,uint minVote) private {

        TokenTransfer storage tokenT = tokenTransfer[_id];

            uint(_vote) == 0 ? tokenT.approve += approvers[msg.sender]
            : tokenT.reject += approvers[msg.sender];

            approvement[msg.sender][_id] = true;

            if(tokenT.approve >=minVote ){

                IERC20(tokenT.tokenAddress).transfer(tokenT.to,tokenT.amount);

                deleteFromList(_id);

            } else if(tokenT.reject >=minVote){

                deleteFromList(_id);
            } 
    }
    function approveFunction(uint _id,Approve _vote) private {
        ApproversEvent storage appE = approversEvent[_id];
        uint minVote;
            
            uint(_vote) == 0 ? appE.approve += approvers[msg.sender]
            : appE.reject += approvers[msg.sender];
            
            minVote = (totalPower - approvers[appE.who]);

            approvement[msg.sender][_id] = true;

            if(appE.approve >= minVote) {
                
                if(uint(appE.appro) == 0){

                    approvers[appE.who] += appE.amount;  

                    totalPower += appE.amount;            
                }
                else {
                     approvers[appE.who] -= appE.amount;

                     totalPower -= appE.amount;

                }
                deleteFromList(_id);
            } else if (appE.reject >= minVote) {
                deleteFromList(_id);
            }
    }

    function deleteFromList(uint _id) private {
        uint group = _id % 10;
        if(group ==1) {
        delete ethTransfer[_id];
        } else if(group == 2) {
        delete tokenTransfer[_id]; 
        } else if(group == 3) {
        delete approversEvent[_id];
        }
        deleteFromEnableList(_id);
    }

    function deleteFromEnableList(uint _id) private {
        uint len = enableTransactions.length;
        for(uint i = 0;i < len;i++ ){
            if(enableTransactions[i] == _id) {
                enableTransactions[i] == enableTransactions[len - 1];
                enableTransactions.pop();
            }
        }
    }
    modifier onlyApprovers() {
        require(approvers[msg.sender]!=0,"only approvers");
        _;
    }

    receive() external payable {}
}

