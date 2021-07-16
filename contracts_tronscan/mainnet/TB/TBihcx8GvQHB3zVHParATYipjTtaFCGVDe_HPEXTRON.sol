//SourceUnit: HPEXTRON_for_verification.sol

pragma solidity >=0.5.8 <0.6.0;


contract TRC20 {
    function transfer(address to, uint tokens) public returns (bool success);
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor(address ownerAddress) public {
        owner = ownerAddress;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public { 
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract HPEXTRON is Owned {
    struct Matrix {
        uint id;
        address owner;
        uint referrals_cnt;
        mapping(uint => uint) referrals;
        uint matrix_referrer;
        address direct_referrer;
        uint from_hpex;
        uint cycles;
        uint last_cycle;
    }

    struct User {
        uint id;
        address referrer;
        uint matrices_cnt;
        uint current_matrix;
        uint last_matrix;
        uint hpex_cooldown_time;
        uint hpex_cooldown_num;
        uint direct_referrals;
    }

    struct HPExLine {
        address owner;
        uint matrix_id;
    }

    struct PaymentStatus { 
        bool is_trx_paid; 
        bool is_tokens_paid; 
        uint matrix_to_renew;
        address referrer;
    }

    struct JackpotPaymentStatus { 
        bool is_trx_paid; 
        bool is_tokens_paid; 
        uint line;
        uint bet_size; 
    }
    
    uint public regCost;

    mapping(address => User) public users;
    mapping(uint => address) public usersById;
    mapping(uint => mapping(uint => uint)) public usersMatrices;
    mapping(uint => Matrix) public matrices;
    mapping(uint => HPExLine) public HPEx;
    mapping (address => PaymentStatus) public paymentQueue; 

    string public name = "HPEX TRON";
    uint public lastUserId = 1;
    uint public lastHPExId = 1;
    uint public lastMatrixId = 1;
    address[] private founders;  
    address public tokenAddress;
    uint public lastCycle = 1;
    uint public renewOffset;
    uint public renewCyclesLimit;
    uint[] private lines  = [10, 50, 200, 500 ];  
    uint[] private betSizes = [10 trx, 50 trx, 200 trx, 800 trx, 2000 trx, 5000 trx]; 
    uint private seed = 1;
    mapping(uint => mapping(uint => address[])) private bets; 
    mapping (address => JackpotPaymentStatus) public jackpotQueue; 

    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Transfer(address indexed user, uint indexed userId, uint indexed amount);
    event NewJackpotWinner(uint line, uint betSize, uint jackpot, address winnerAddress); 
    event ChangeRegistrationCost(uint newCost); 
    event ChangeTokenAddress(address newTokenAddress);
    event ChangeRenewCyclesLimit(uint newCoolDown);
    event SkipMatrix(uint matrixId); 

    constructor(address ownerAddress, address _tokenAddress, address[] memory _founders) Owned (ownerAddress) public {
        founders = _founders;
        tokenAddress = _tokenAddress;

        users[owner] = User({
            id: lastUserId,
            referrer: address(0),
            matrices_cnt: 0,
            current_matrix: 0,
            last_matrix: 0,
            hpex_cooldown_time: 0,
            hpex_cooldown_num: 0,
            direct_referrals: 0
            });

        usersById[lastUserId] = owner;

        matrices[lastMatrixId] = Matrix({
            id: lastUserId,
            owner: owner,
            referrals_cnt: 0,
            matrix_referrer: 0,
            direct_referrer: address(0),
            from_hpex: 0,
            cycles: 0,
            last_cycle: 0
            });

        usersMatrices[users[owner].id][users[owner].matrices_cnt] = lastMatrixId;
        users[owner].matrices_cnt++;
        users[owner].current_matrix = 0;

        HPEx[lastHPExId] = HPExLine({
            matrix_id: lastMatrixId,
            owner: owner
            });

        lastHPExId++;
        lastMatrixId++;
        lastUserId++;

        regCost = 300000000;
        renewCyclesLimit = 3;
    }

    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function matrixReferrals(uint matrixId, uint index) public view returns (uint) {
        return matrices[matrixId].referrals[index];
    }

    function changeRegistrationCost(uint newCost) public  onlyOwner returns (bool success) {
        regCost = newCost;
        emit ChangeRegistrationCost(newCost);
        return true;
    }
    
    function changeTokenAddress (address newTokenAddress) public onlyOwner returns (bool success) {
        tokenAddress = newTokenAddress;
        emit ChangeTokenAddress(newTokenAddress);
        return true;
    }

    function changeRenewCyclesLimit (uint newLimit) public onlyOwner returns (bool success) { 
        require (newLimit > 0, "the value must be greater than 0");
        renewCyclesLimit = newLimit;
        emit ChangeRenewCyclesLimit(newLimit);
        return true;
    }




    function receiveTransfer(address from, uint tokens, bytes memory data) public returns (string memory status) {
        require(msg.sender == tokenAddress, "Unknown token");

        string memory result;
        if (data.length == 0) { 
            require(tokens == regCost * 1000000000000 , "Wrong token amount");
            require(!paymentQueue[from].is_tokens_paid, "tokens paid, TRXs awaiting");

            if (!isUserExists(from)) {
                if (!paymentQueue[from].is_trx_paid) {
                    paymentQueue[from].is_tokens_paid = true;
                    result = "Tokens accepted. Waiting TRX payment for registration completion";
                } else {
                    paymentQueue[from].is_trx_paid = false;
                    registration(from, paymentQueue[from].referrer);
                    result = "Registration is completed";
                }
            } else {
                require(users[from].matrices_cnt < 150, "max 150 hpex allowed");

                if (!paymentQueue[from].is_trx_paid) {
                    paymentQueue[from].is_tokens_paid = true;
                    result = "Tokens accepted. Waiting TRX payment for HPEX purchase/renew";
                } else {
                    paymentQueue[from].is_trx_paid = false;
                    if (paymentQueue[from].matrix_to_renew != 0) {
                        renew(from, paymentQueue[from].matrix_to_renew);
                        paymentQueue[from].matrix_to_renew = 0;
                        result = "Renew is completed";
                    } else {
                        purchase(from);
                        result = "Purchase is completed";
                    }
                }
            }
        } else {
            require(!jackpotQueue[from].is_tokens_paid, "already paid jackpot cost in tokens, TRX awaiting");
            
            uint line = deserializeUint(data);
            uint betSize = tokens / 1000000000000;

            if (!jackpotQueue[from].is_trx_paid) {
                require(betSize == 10 trx || betSize == 50 trx || betSize == 200 trx || betSize == 800 trx || betSize == 2000 trx || betSize == 5000 trx, "No such bet size"); 
                require(line == 10 || line == 50 || line == 200 || line == 500, "No such bet line"); 
                jackpotQueue[from].is_tokens_paid = true;
                jackpotQueue[from].line = line;
                jackpotQueue[from].bet_size = betSize;
                result = "Waiting TRX payment for jackpot bet acceptance";
            } else {
                require(jackpotQueue[from].line == line && jackpotQueue[from].bet_size == betSize, "wrong line or bet size");
                result = addJackpotBet(jackpotQueue[from].line, jackpotQueue[from].bet_size);
                delete jackpotQueue[from];
            }
        }

        return result;
    }     

    function register(address referrer) public payable {
        require(msg.value == regCost, "not correct registration cost");
        require(!isUserExists(msg.sender), "user exists");
        require(isUserExists(referrer), "referrer not exists");
        require(!paymentQueue[msg.sender].is_trx_paid, "already paid registration cost in TRX, tokens awaiting"); 
        
        if (!paymentQueue[msg.sender].is_tokens_paid) {
            paymentQueue[msg.sender].is_trx_paid = true;
            paymentQueue[msg.sender].referrer = referrer;
        } else {
            paymentQueue[msg.sender].is_tokens_paid = false;
            registration(msg.sender, referrer);
        }
    }

    function purchaseHPExPosition() public payable {
        require(msg.value == regCost, "not correct purchase cost"); 
        require(isUserExists(msg.sender), "user not exists");
        require(users[msg.sender].matrices_cnt < 150, "max 150 hpex allowed");
        require(!paymentQueue[msg.sender].is_trx_paid, "already paid in TRX, tokens awaiting");


        if(!paymentQueue[msg.sender].is_tokens_paid) {
            paymentQueue[msg.sender].is_trx_paid = true;
        } else {
            paymentQueue[msg.sender].is_tokens_paid = false;
            purchase(msg.sender);
        }
    }
    
    function renewMatrix(uint matrixToRenew) public payable {
        require(msg.value == regCost, "not correct renew cost");
        require(isUserExists(msg.sender), "user not exists");
        require(!paymentQueue[msg.sender].is_trx_paid, "already paid in TRX, token payment awaiting");
        require(matrices[matrixToRenew].owner == msg.sender, "not user's matrix");

        if(!paymentQueue[msg.sender].is_tokens_paid) {
            paymentQueue[msg.sender].is_trx_paid = true;
            paymentQueue[msg.sender].matrix_to_renew = matrixToRenew;
        } else {
            paymentQueue[msg.sender].is_tokens_paid = false;
            renew(msg.sender, matrixToRenew);
        }
    }




    function registration(address userAddress, address referrerAddress) private {
        users[userAddress] = User({
            id: lastUserId,
            referrer: referrerAddress,
            matrices_cnt: 0,
            current_matrix: 0,
            last_matrix: 0,
            hpex_cooldown_time: 0,
            hpex_cooldown_num: 0,
            direct_referrals: 0
            });

        usersById[lastUserId] = userAddress;

        lastUserId++;

        users[referrerAddress].direct_referrals++;

        payUser(referrerAddress, regCost * 10 / 100); 
        payFounders(regCost * 10 / 100); 
        joinHPEx(lastMatrixId, userAddress, false, false);
        fillMatrix(userAddress, referrerAddress, 0);
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }

    function purchase(address userAddress) private  {
        if (users[userAddress].hpex_cooldown_time < now - 86400) {
            users[userAddress].hpex_cooldown_time = now;
            users[userAddress].hpex_cooldown_num = 1;
        } else {
            if (users[userAddress].hpex_cooldown_num < 3) {
                users[userAddress].hpex_cooldown_num++;
            } else {
                revert("24h purchase limit");
            }
        }

        payUser(users[userAddress].referrer, regCost * 10 / 100); 
        payFounders(regCost * 10 / 100); 
        joinHPEx(lastMatrixId, userAddress, false, false); 
        fillMatrix(userAddress, users[userAddress].referrer, 1);
    }

    function renew(address userAddress, uint matrixToRenew) private  { 
        payUser(users[userAddress].referrer, regCost * 10 / 100);
        payFounders(regCost * 10 / 100); 
        joinHPEx(matrixToRenew, userAddress, false, true); 
        payForMatrix(matrices[matrixToRenew].matrix_referrer);
    }

    function joinHPEx(uint matrixId, address matrixOwner, bool isCycleFinished, bool isRenew) private {
        if (!isRenew) {
            HPEx[lastHPExId] = HPExLine({
                matrix_id: matrixId,
                owner: matrixOwner
                });
            lastHPExId++;

            if (matrices[matrixId].id != 0) {
                matrices[matrixId].cycles++;
                matrices[matrixId].last_cycle = lastCycle; 
            }
        } else {
            matrices[matrixId].last_cycle = 0; 
        }

        if (!isCycleFinished) {
            if (lastCycle != 1) {
                while (matrices[HPEx[renewOffset + lastCycle - 1].matrix_id].last_cycle != 0 
                        && (lastCycle - matrices[HPEx[renewOffset + lastCycle - 1].matrix_id].last_cycle > renewCyclesLimit) 
                        && (lastCycle + renewOffset < lastHPExId - 2)) { 
                    emit SkipMatrix(HPEx[renewOffset + lastCycle - 1].matrix_id); 
                    renewOffset++;
                }

                payHPEx(HPEx[renewOffset + lastCycle - 1].owner);
                joinHPEx(HPEx[renewOffset + lastCycle - 1].matrix_id, HPEx[renewOffset + lastCycle - 1].owner, !isCycleFinished, false);
                payForMatrix(matrices[HPEx[renewOffset + lastCycle - 1].matrix_id].matrix_referrer);
                lastCycle++;
            } else {
                payHPEx(owner);
                payForMatrix(0);
                lastCycle++;
            }
        }
    }

    function payForMatrix(uint slotId) private {
        if (slotId == 0) {
            payUser(matrices[1].owner, regCost * 25 / 100); 
            return ;
        }

        uint unspent = 0;
        address lastEligible;
        uint level1 = slotId;

        if (users[matrices[level1].owner].direct_referrals < 4) { 
            unspent = regCost * 25 / 1000;
        } else {
            payUser(matrices[level1].owner, regCost * 25 / 1000); 
            lastEligible = matrices[level1].owner;
        }

        uint level2 = matrices[level1].matrix_referrer;

        if (level2 == 0) {
            if (lastEligible != address(0)) {
                payUser(lastEligible, regCost * 225 / 1000); 
            } else {
                payUser(matrices[1].owner, regCost * 25 / 100); 
            }
            return;
        } else if (users[matrices[level2].owner].direct_referrals < 4) { 
            unspent += regCost * 5 / 100;
        } else {
            payUser(matrices[level2].owner, unspent + regCost * 5 / 100); 
            lastEligible = matrices[level2].owner;
            unspent = 0;
        }

        uint level3 = matrices[level2].matrix_referrer;

        if (level3 == 0) {
            if (lastEligible != address(0)) {
                payUser(lastEligible, regCost * 175 / 1000 + unspent); 
            } else {
                payUser(matrices[1].owner, regCost * 25 / 100); 
            }
            return;
        } else if (users[matrices[level3].owner].direct_referrals < 4) { 
            unspent += regCost * 75 / 1000;
        } else {
            payUser(matrices[level3].owner, unspent + regCost * 75 / 1000);
            lastEligible = matrices[level3].owner;
            unspent = 0;
        }

        uint level4 = matrices[level3].matrix_referrer;

        if (level4 == 0) {
            if (lastEligible != address(0)) {
                payUser(lastEligible, regCost * 10 / 100 + unspent); 
            } else {
                payUser(matrices[1].owner, regCost * 25 / 100); 
            }
            return;
        } else if (users[matrices[level4].owner].direct_referrals < 4) { 
            unspent += regCost * 10 / 100;
        } else {
            payUser(matrices[level4].owner, unspent + regCost * 10 / 100); 
            lastEligible = matrices[level4].owner;
            unspent = 0;
        }

        if (unspent == regCost * 25 / 100) {
            while (users[matrices[level4].owner].direct_referrals < 4) {
                if (level4 == 0) {
                    payUser(matrices[1].owner, unspent); 
                }

                level4 = matrices[level4].matrix_referrer;
            }

            payUser(matrices[level4].owner, unspent); 
        } else {
            payUser(lastEligible, unspent);
        }
    }

    function fillMatrix(address user, address referrer, uint from_hpex) private {
        if (referrer == address(0)) {
            referrer = usersById[1];
        }

        uint slotId = findSlot(usersMatrices[users[referrer].id][users[referrer].current_matrix], 1, 4);

        if (slotId == 0) {
            if (users[referrer].current_matrix == users[referrer].matrices_cnt-1) {
                revert("all matrices are full");
            }

            users[referrer].current_matrix++;
            slotId = findSlot(usersMatrices[users[referrer].id][users[referrer].current_matrix], 1, 4);
        }

        payForMatrix(slotId);

        matrices[lastMatrixId] = Matrix({
            id: lastMatrixId,
            owner: user,
            referrals_cnt: 0,
            matrix_referrer: slotId,
            from_hpex: from_hpex,
            direct_referrer: referrer,
            cycles: 0,
            last_cycle: 0
            });

        usersMatrices[users[user].id][users[user].matrices_cnt] = lastMatrixId;
        users[user].matrices_cnt++;
        users[user].last_matrix = lastMatrixId;

        matrices[lastMatrixId].matrix_referrer = slotId;

        lastMatrixId++;

        matrices[slotId].referrals[matrices[slotId].referrals_cnt] = lastMatrixId-1;
        matrices[slotId].referrals_cnt++;
    }

    function findSlot(uint matrix, uint level, uint maxLevel) private returns (uint) {
        if (level > maxLevel) {
            return(0);
        }

        if (matrices[matrix].referrals_cnt < 4) {
            return(matrix);
        }

        uint tmpMaxLevel = level+1;

        while (tmpMaxLevel <= maxLevel) {
            uint i=0;

            do {
                uint slot = findSlot(matrices[matrix].referrals[i], level+1, tmpMaxLevel);
                if (slot != 0) {
                    return(slot);
                }

                i++;
            } while (i<4);

            tmpMaxLevel++;
        }

        return(0);
    }

    function payUser(address user, uint amount) private {
        emit Transfer(user, users[user].id, amount);
        address(uint160(user)).transfer(amount);
        require(payInTokens(user, amount));
    }

    function payHPEx(address user) private {
        emit Transfer(user, users[user].id, regCost * 30 / 100);
        address(uint160(user)).transfer(regCost * 30 / 100); 
        require(payInTokens(user, regCost * 30 / 100)); 
    }

    function payFounders(uint amount) private {
        uint founderAmount = amount/founders.length;

		for (uint i=0; i < founders.length; i++) {
			emit Transfer(founders[i], 0, founderAmount);
			address(uint160(founders[i])).transfer(founderAmount);
            payInTokens(founders[i], founderAmount);
		}
    }

    function payInTokens(address to, uint amountInTrx) private returns (bool success) {
        uint amountInTokens = amountInTrx * 1000000000000;
        return TRC20(tokenAddress).transfer(to, amountInTokens);
    }


    

    function joinJackpot(uint line) public payable returns(string memory status) {
        require(!jackpotQueue[msg.sender].is_trx_paid, "already paid TRXs, tokens awaiting");
        
        string memory result;
        if (!jackpotQueue[msg.sender].is_tokens_paid) {
            require(msg.value == 10 trx || msg.value == 50 trx || msg.value == 200 trx || msg.value == 800 trx || msg.value == 2000 trx || msg.value == 5000 trx, "No such bet size"); 
            require(line == 10 || line == 50 || line == 200 || line == 500, "No such bet line");  
            jackpotQueue[msg.sender].line = line;
            jackpotQueue[msg.sender].is_trx_paid = true;
            jackpotQueue[msg.sender].bet_size = msg.value;
            result = "Waiting token payment for jackpot bet acceptance";
        } else {
            require(jackpotQueue[msg.sender].line == line && jackpotQueue[msg.sender].bet_size == msg.value, "wrong line or bet size");
            result = addJackpotBet(jackpotQueue[msg.sender].line, jackpotQueue[msg.sender].bet_size);
            delete jackpotQueue[msg.sender];
        }

        return result;
    }

    function addJackpotBet(uint line, uint betSize) private returns(string memory status) {
        bets[line][betSize].push(msg.sender);
        
        if (bets[line][betSize].length == line) { 
            defineWinner(line);
            return ("This line winner is defined");
        } else {
            return ("Your bet is accepted");
        }
    }
    
    function betsLineFilling(uint line, uint betSize) public view returns (uint length) { 
        return bets[line][betSize].length;
    }

    function betsLineAddresses(uint line, uint betSize) public view returns (address[] memory participants) { 
        return bets[line][betSize];
    }

    function defineWinner(uint line) private {  
        uint additionalSeed = uint(blockhash(block.number - 1)); 
        uint rnd = 0;
        
        while(rnd < line) { 
            rnd += additionalSeed * seed;
        }
        
        address winnerAddress = bets[line][msg.value][rnd % line];
        uint winnerAmount = line * msg.value * 9 / 10;
        uint transactionalCost = line * msg.value / 10;
        
        address(uint160(winnerAddress)).transfer(winnerAmount);
        payInTokens(winnerAddress, winnerAmount);
        emit NewJackpotWinner(line, msg.value, winnerAmount, winnerAddress);

        payFounders(transactionalCost);

        delete bets[line][msg.value]; 

        seed = additionalSeed;
    }

    function deserializeUint(bytes memory data) private pure returns (uint)
    {
        uint32 res = 0;

        for (uint i = 0; i < 4; i++)
        {
            uint32 temp = uint32(uint8(data[i]));
            temp <<= 8 * i;
            res ^= temp;
        }

        return uint(res);
    }
}