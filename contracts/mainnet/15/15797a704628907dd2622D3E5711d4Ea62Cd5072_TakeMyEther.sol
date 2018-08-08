pragma solidity ^0.4.19;

library itMaps {
    /* itMapAddressUint
         address =>  Uint
    */
    struct entryAddressUint {
    // Equal to the index of the key of this item in keys, plus 1.
    uint keyIndex;
    uint value;
    }

    struct itMapAddressUint {
    mapping(address => entryAddressUint) data;
    address[] keys;
    }

    function insert(itMapAddressUint storage self, address key, uint value) internal returns (bool replaced) {
        entryAddressUint storage e = self.data[key];
        e.value = value;
        if (e.keyIndex > 0) {
            return true;
        } else {
            e.keyIndex = ++self.keys.length;
            self.keys[e.keyIndex - 1] = key;
            return false;
        }
    }

    function remove(itMapAddressUint storage self, address key) internal returns (bool success) {
        entryAddressUint storage e = self.data[key];
        if (e.keyIndex == 0)
        return false;

        if (e.keyIndex <= self.keys.length) {
            // Move an existing element into the vacated key slot.
            self.data[self.keys[self.keys.length - 1]].keyIndex = e.keyIndex;
            self.keys[e.keyIndex - 1] = self.keys[self.keys.length - 1];
            self.keys.length -= 1;
            delete self.data[key];
            return true;
        }
    }

    function destroy(itMapAddressUint storage self) internal  {
        for (uint i; i<self.keys.length; i++) {
            delete self.data[ self.keys[i]];
        }
        delete self.keys;
        return ;
    }

    function contains(itMapAddressUint storage self, address key) internal constant returns (bool exists) {
        return self.data[key].keyIndex > 0;
    }

    function size(itMapAddressUint storage self) internal constant returns (uint) {
        return self.keys.length;
    }

    function get(itMapAddressUint storage self, address key) internal constant returns (uint) {
        return self.data[key].value;
    }

    function getKeyByIndex(itMapAddressUint storage self, uint idx) internal constant returns (address) {
        return self.keys[idx];
    }

    function getValueByIndex(itMapAddressUint storage self, uint idx) internal constant returns (uint) {
        return self.data[self.keys[idx]].value;
    }
}

contract ERC20 {
    function totalSupply() public constant returns (uint256 supply);
    function balanceOf(address who) public constant returns (uint value);
    function allowance(address owner, address spender) public constant returns (uint _allowance);

    function transfer(address to, uint value) public returns (bool ok);
    function transferFrom(address from, address to, uint value) public returns (bool ok);
    function approve(address spender, uint value) public returns (bool ok);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract TakeMyEther is ERC20{
    using itMaps for itMaps.itMapAddressUint;

    uint private initialSupply = 2800000;
    uint public soldTokens = 0; //reduces when somebody returns money
    string public constant name = "TakeMyEther";
    string public constant symbol = "TMEther";
    address public TakeMyEtherTeamAddress;

    itMaps.itMapAddressUint tokenBalances; //amount of tokens each address holds
    mapping (address => uint256) weiBalances; //amount of Wei, paid for tokens that smb holds. Used only before project completed.
    mapping (address => uint256) weiBalancesReturned;

    uint public percentsOfProjectComplete = 0;
    uint public lastStageSubmitted;
    uint public lastTimeWithdrawal;

    uint public constant softCapTokensAmount = 500000;
    uint public constant hardCapTokensAmount = 2250000;

    uint public constant lockDownPeriod = 1 weeks;
    uint public constant minimumStageDuration = 2 weeks;

    bool public isICOfinalized = false;
    bool public projectCompleted = false;

    modifier onlyTeam {
        if (msg.sender == TakeMyEtherTeamAddress) {
            _;
        }
    }

    mapping (address => mapping (address => uint256)) allowed;

    event StageSubmitted(uint last);
    event etherPassedToTheTeam(uint weiAmount, uint when);
    event etherWithdrawFromTheContract(address tokenHolder, uint numberOfTokensSoldBack, uint weiValue);
    event Burned(address indexed from, uint amount);
    event DividendsTransfered(address to, uint tokensAmount, uint weiAmount);

    // ERC20 interface implementation

    function totalSupply() public constant returns (uint256) {
        return initialSupply;
    }

    function balanceOf(address tokenHolder) public view returns (uint256 balance) {
        return tokenBalances.get(tokenHolder);
    }

    function allowance(address owner, address spender) public constant returns (uint256) {
        return allowed[owner][spender];
    }

    function transfer(address to, uint value) public returns (bool success) {
        if (tokenBalances.get(msg.sender) >= value && value > 0) {
            if (to == address(this)) { // if you send even 1 token back to the contract, it will return all available funds to you
                returnAllAvailableFunds();
                return true;
            }
            else {
                return transferTokensAndEtherValue(msg.sender, to, value, getAverageTokenPrice(msg.sender) * value);
            }
        } else return false;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        if (tokenBalances.get(from)>=value && allowed[from][to] >= value && value > 0) {
            if (transferTokensAndEtherValue(from, to, value, getAverageTokenPrice(from) * value)) {
                allowed[from][to] -= value;
                return true;
            }
            return false;
        }
        return false;
    }

    function approve(address spender, uint value) public returns (bool success) {
        if ((value != 0) && (tokenBalances.get(msg.sender) >= value)){
            allowed[msg.sender][spender] = value;
            emit Approval(msg.sender, spender, value);
            return true;
        } else{
            return false;
        }
    }

    // Constructor, fallback, return funds

    function TakeMyEther() public {
        TakeMyEtherTeamAddress = msg.sender;
        tokenBalances.insert(address(this), initialSupply);
        lastStageSubmitted = now;
    } //tested

    function () public payable {
        require (!projectCompleted);
        uint weiToSpend = msg.value; //recieved value
        uint currentPrice = getCurrentSellPrice(); //0.5 ETH or 1 ETH for 1000 tokens
        uint valueInWei = 0;
        uint valueToPass = 0;

        if (weiToSpend < currentPrice) {// return ETH back if nothing to buy
            return;
        }

        if (!tokenBalances.contains(msg.sender))
        tokenBalances.insert(msg.sender, 0);

        if (soldTokens < softCapTokensAmount) {
            uint valueLeftForSoftCap = softCapTokensAmount - soldTokens;
            valueToPass = weiToSpend / currentPrice;

            if (valueToPass > valueLeftForSoftCap)
            valueToPass = valueLeftForSoftCap;

            valueInWei = valueToPass * currentPrice;
            weiToSpend -= valueInWei;
            soldTokens += valueToPass;
            weiBalances[address(this)] += valueInWei;
            transferTokensAndEtherValue(address(this), msg.sender, valueToPass, valueInWei);
        }

        currentPrice = getCurrentSellPrice(); //renew current price

        if (weiToSpend < currentPrice) {
            return;
        }

        if (soldTokens < hardCapTokensAmount && soldTokens >= softCapTokensAmount) {
            uint valueLeftForHardCap = hardCapTokensAmount - soldTokens;
            valueToPass = weiToSpend / currentPrice;

            if (valueToPass > valueLeftForHardCap)
            valueToPass = valueLeftForHardCap;

            valueInWei = valueToPass * currentPrice;
            weiToSpend -= valueInWei;
            soldTokens += valueToPass;
            weiBalances[address(this)] += valueInWei;
            transferTokensAndEtherValue(address(this), msg.sender, valueToPass, valueInWei);
        }

        if (weiToSpend / 10**17 > 1) { //return unspent funds if they are greater than 0.1 ETH
            msg.sender.transfer(weiToSpend);
        }
    }

    function returnAllAvailableFunds() public {
        require (tokenBalances.contains(msg.sender)); //you need to be a tokenHolder
        require (!projectCompleted); //you can not return tokens after project is completed

        uint avPrice = getAverageTokenPrice(msg.sender);
        weiBalances[msg.sender] = getWeiAvailableToReturn(msg.sender); //depends on project completeness level

        uint amountOfTokensToReturn = weiBalances[msg.sender] / avPrice;

        require (amountOfTokensToReturn>0);

        uint valueInWei = weiBalances[msg.sender];

        transferTokensAndEtherValue(msg.sender, address(this), amountOfTokensToReturn, valueInWei);
        emit etherWithdrawFromTheContract(msg.sender, amountOfTokensToReturn, valueInWei);
        weiBalances[address(this)] -= valueInWei;
        soldTokens -= amountOfTokensToReturn;
        msg.sender.transfer(valueInWei);
    }

    // View functions

    function getWeiBalance(address a) public view returns (uint) {
        return weiBalances[a];
    }

    function getWeiAvailableToReturn(address holder) public view returns (uint amount) {
        if (!isICOfinalized) return weiBalances[holder];
        uint percentsBlocked = 0;
        if (percentsOfProjectComplete > 10 && lastStageSubmitted + lockDownPeriod > now)
        percentsBlocked = percentsOfProjectComplete - 10;
        else
        percentsBlocked = percentsOfProjectComplete;
        return ((weiBalances[holder]  / 100) * (100 - percentsOfProjectComplete));
    }

    function getAverageTokenPrice(address holder) public view returns (uint avPriceInWei) {
        return weiBalances[holder] / tokenBalances.get(holder);
    }

    function getNumberOfTokensForTheTeam() public view returns (uint amount) {
        if (soldTokens == softCapTokensAmount) return soldTokens * 4; // 80%
        if (soldTokens == hardCapTokensAmount) return soldTokens/4; // 20%
        uint teamPercents = (80 - ((soldTokens - softCapTokensAmount) / ((hardCapTokensAmount - softCapTokensAmount)/60)));
        return ((soldTokens / (100 - teamPercents)) * teamPercents); // tokens for the team
    }

    function getCurrentSellPrice() public view returns (uint priceInWei) {
        if (!isICOfinalized) {
            if (soldTokens < softCapTokensAmount) return 10**14 * 5 ; //this is equal to 0.0005 ETH
            else return 10**15; //this is equal to 0.001 ETH
        }
        else { //if someone returns tokens after ICO finished, he can buy them until project is finished. But the price will depend on the project completeness level.
            if (!projectCompleted) //if project is finished, no one can buy tokens
            return (1 * 10**15 + 5 * (percentsOfProjectComplete * 10**13)) ; //each percent of completeness adds 5% to the tokenPrice.
            else return 0; // there is no problem, because project is completed and fallback function won&#39;t work;
        }
    }

    function getAvailableFundsForTheTeam() public view returns (uint amount) {
        if (percentsOfProjectComplete == 100) return address(this).balance; // take all the rest
        return (address(this).balance /(100 - (percentsOfProjectComplete - 10))) * 10; // take next 10% of funds, left on the contract.
        /*So if, for example, percentsOfProjectComplete is 30 (increased by 10 from previous stage)
        there are 80% of funds, left on the contract. So we devide balance by 80 to get 1%, and then multiply by 10*/
    }

    // Team functions

    function finalizeICO() public onlyTeam {
        require(!isICOfinalized); // this function can be called only once
        if (soldTokens < hardCapTokensAmount)
        require (lastStageSubmitted + minimumStageDuration < now); // ICO duration is at least 2 weeks
        require(soldTokens >= softCapTokensAmount); //means, that the softCap Reached
        uint tokensToPass = passTokensToTheTeam(); //but without weiValue, so the team can not withdraw ether by returning tokens to the contract
        burnUndistributedTokens(tokensToPass);//tokensToPass); // undistributed tokens are destroyed
        lastStageSubmitted = now;
        emit StageSubmitted(lastStageSubmitted);
        increaseProjectCompleteLevel(); // Now, team can withdraw 10% of funds raised to begin the project
        passFundsToTheTeam();
        isICOfinalized = true;
    }

    function submitNextStage() public onlyTeam returns (bool success) {
        if (lastStageSubmitted + minimumStageDuration > now) return false; //Team submitted the completeness of previous stage more then 2 weeks before.
        lastStageSubmitted = now;
        emit StageSubmitted(lastStageSubmitted);
        increaseProjectCompleteLevel();
        return true;
    }

    function unlockFundsAndPassEther() public onlyTeam returns (bool success) {
        require (lastTimeWithdrawal<=lastStageSubmitted);
        if (lastStageSubmitted + lockDownPeriod > now) return false; //funds can not be passed until lockDownPeriod ends
        if (percentsOfProjectComplete == 100 && !projectCompleted) {
            projectCompleted = true;
            if (tokenBalances.get(address(this))>0) {
                uint toTransferAmount = tokenBalances.get(address(this));
                tokenBalances.insert(TakeMyEtherTeamAddress, tokenBalances.get(address(this)) + tokenBalances.get(TakeMyEtherTeamAddress));
                tokenBalances.insert(address(this), 0);
                emit Transfer(address(this), TakeMyEtherTeamAddress, toTransferAmount);
            }
        }
        passFundsToTheTeam();
        return true;
    }

    // Receive dividends

    function topUpWithEtherAndTokensForHolders(address tokensContractAddress, uint tokensAmount) public payable {
        uint weiPerToken = msg.value / initialSupply;
        uint tokensPerToken = 100 * tokensAmount / initialSupply; //Multiplication for more precise amount
        uint weiAmountForHolder = 0;
        uint tokensForHolder = 0;

        for (uint i = 0; i< tokenBalances.size(); i += 1) {
            address tokenHolder = tokenBalances.getKeyByIndex(i);
            if (tokenBalances.get(tokenHolder)>0) {
                weiAmountForHolder = tokenBalances.get(tokenHolder)*weiPerToken;
                tokensForHolder = tokenBalances.get(tokenHolder) * tokensPerToken / 100; // Dividing because of the previous multiplication
                tokenHolder.transfer(weiAmountForHolder); //This will pass a certain amount of ether to TakeMyEther platform tokenHolders
                if (tokensContractAddress.call(bytes4(keccak256("authorizedTransfer(address,address,uint256)")), msg.sender, tokenHolder, tokensForHolder)) //This will pass a certain amount of tokens to TakeMyEther platform tokenHolders
                emit DividendsTransfered(tokenHolder, tokensForHolder, weiAmountForHolder);
            }
        }
    }

    function passUndistributedEther() public {
        require (projectCompleted);
        uint weiPerToken = (address(this).balance * 100) / initialSupply;

        for (uint i = 0; i< tokenBalances.size(); i += 1) {
            address tokenHolder = tokenBalances.getKeyByIndex(i);
            if (tokenBalances.get(tokenHolder)>0) {
                uint weiAmountForHolder = (tokenBalances.get(tokenHolder)*weiPerToken)/100;
                tokenHolder.transfer(weiAmountForHolder); //This will pass a certain amount of ether to TakeMyEther platform tokenHolders
                emit DividendsTransfered(tokenHolder, 0, weiAmountForHolder);
            }
        }
    } // When project is finished and Dividends are passed to the tokenHolders, there is some wei, left on the contract. Gradually, there can be a large amount of wei left, so it should be also distributed among tokenHolders.

    // Internal functions

    function transferTokensAndEtherValue(address from, address to, uint value, uint weiValue) internal returns (bool success){
        if (tokenBalances.contains(from) && tokenBalances.get(from) >= value) {
            tokenBalances.insert(to, tokenBalances.get(to) + value);
            tokenBalances.insert(from, tokenBalances.get(from) - value);

            weiBalances[from] -= weiValue;
            weiBalances[to] += weiValue;

            emit Transfer(from, to, value);
            return true;
        }
        return false;
    }

    function passFundsToTheTeam() internal {
        uint weiAmount = getAvailableFundsForTheTeam();
        TakeMyEtherTeamAddress.transfer(weiAmount);
        emit etherPassedToTheTeam(weiAmount, now);
        lastTimeWithdrawal = now;
    }

    function passTokensToTheTeam() internal returns (uint tokenAmount) { //This function passes tokens to the team without weiValue, so the team can not withdraw ether by returning tokens to the contract
        uint tokensToPass = getNumberOfTokensForTheTeam();
        tokenBalances.insert(TakeMyEtherTeamAddress, tokensToPass);
        weiBalances[TakeMyEtherTeamAddress] = 0; // those tokens don&#39;t cost any ether
        emit Transfer(address(this), TakeMyEtherTeamAddress, tokensToPass);
        return tokensToPass;
    }

    function increaseProjectCompleteLevel() internal {
        if (percentsOfProjectComplete<60)
        percentsOfProjectComplete += 10;
        else
        percentsOfProjectComplete = 100;
    }

    function burnUndistributedTokens(uint tokensToPassToTheTeam) internal {
        uint toBurn = initialSupply - (tokensToPassToTheTeam + soldTokens);
        initialSupply -=  toBurn;
        tokenBalances.insert(address(this), 0);
        emit Burned(address(this), toBurn);
    }
}