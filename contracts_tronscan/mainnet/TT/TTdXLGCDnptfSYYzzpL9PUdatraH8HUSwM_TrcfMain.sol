//SourceUnit: TrxfMain.sol

pragma solidity 0.4.25;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity 0.4.25;


    library DappDatasets {

        struct Player {

            uint level;

            uint wallet;

            uint withdrawalAmount;

            address superiorAddr;

            bool isExist;

            bool isPartner;

            uint rechargeAmountV1;

            uint rechargeAmountV2;

            uint rechargeAmountV3;

            uint rechargeAmountV4;

            uint rechargeAmountV5;

            uint resTime;

        }

    }

    contract TrcfMain {

        address owner;

        address specifyAddr;

        address[] allPlayer;

        bool public mineV1 = true;

        bool public mineV2 = false;

        bool public mineV3 = false;

        bool public mineV4 = false;

        bool public mineV5 = false;

        TrcfToken trcfToken;

        mapping(address => DappDatasets.Player) public playerMap;
        mapping(address => bool) Partner;
  
        constructor(
            address _owner,
            address _specifyAddr,
            address _TrcfAddr
        )  public {
            owner = _owner;
            DappDatasets.Player memory player = DappDatasets.Player(
                {
                    level : 0,
                    wallet : 0,
                    withdrawalAmount : 0, 
                    superiorAddr : address(0x0),
                    isExist : true, 
                    isPartner : false, 
                    rechargeAmountV1 : 0,
                    rechargeAmountV2 : 0,
                    rechargeAmountV3 : 0,
                    rechargeAmountV4 : 0,
                    rechargeAmountV5 : 0,
                    resTime : now
                }
            );
            specifyAddr = _specifyAddr;
            playerMap[owner] = player;
            trcfToken = TrcfToken(_TrcfAddr);
        }

        function() public payable {
            withdrawImpl(msg.sender);
        }

        event LogInvestIn(address indexed userAddress, uint inputAmount, uint resTime, uint mineID, address superiorAddr, uint level, uint investType);
        event LogPartner(address indexed userAddress, uint inputAmount, uint resTime);
        event LogWithdraw(address indexed userAddress, uint amount, uint resTime);

        function addWallet(address addr, uint num) internal {
            playerMap[addr].wallet = SafeMath.add(playerMap[addr].wallet, num);
        }

        function subWallet(address addr, uint num) internal {
            playerMap[addr].wallet = SafeMath.sub(playerMap[addr].wallet, num);
        }

        function addWalletService(address addr, uint num) external {
            require(owner == msg.sender, "Insufficient permissions");
            addWallet(addr, num);
        }

        function subWalletService(address addr, uint num) external {
            require(owner == msg.sender, "Insufficient permissions");
            subWallet(addr, num);
        }

        function isEnoughBalance(uint sendMoney) private view returns (bool, uint){
            if (sendMoney >= address(this).balance) {
                return (false, address(this).balance);
            } else {
                return (true, sendMoney);
            }
        }

        function withdrawImpl(address addr) internal {
            require(playerMap[addr].wallet > 0, "Insufficient wallet balance");
            bool isEnough;
            uint sendMoney = playerMap[addr].wallet;
            if(sendMoney > 0){

                (isEnough, sendMoney) = isEnoughBalance(sendMoney);
                if (isEnough && sendMoney >= 100 * 10 ** 6) {
                    uint handlingFee = SafeMath.div(sendMoney, 10);
                    playerMap[addr].wallet = 0;
                    playerMap[addr].withdrawalAmount = SafeMath.add(playerMap[addr].withdrawalAmount, sendMoney);
                    addr.transfer(SafeMath.sub(sendMoney, handlingFee));
                    emit LogWithdraw(addr, sendMoney, now);
                }else {
                    require(sendMoney == 0,"withdraw fail");
                    return;
                }

            }
        }

        function withdrawService() external {
            withdrawImpl(msg.sender);
        }

        function intoColdWallet(uint amount) external {
            require(owner == msg.sender, "Insufficient permissions");
            specifyAddr.transfer(amount);
        }

        function resetMinePool(bool V1, bool V2, bool V3, bool V4, bool V5) external {
            require(owner == msg.sender, "Insufficient permissions");
            mineV1 = V1;
            mineV2 = V2;
            mineV3 = V3;
            mineV4 = V4;
            mineV5 = V5;
        }

        function addUserRechargeAmount(address addr, uint num1, uint num2, uint num3, uint num4, uint num5) external {
            require(owner == msg.sender, "Insufficient permissions");
            if (num1 > 0) { playerMap[addr].rechargeAmountV1 = SafeMath.add(playerMap[addr].rechargeAmountV1, num1); }
            if (num2 > 0) { playerMap[addr].rechargeAmountV2 = SafeMath.add(playerMap[addr].rechargeAmountV2, num2); }
            if (num3 > 0) { playerMap[addr].rechargeAmountV3 = SafeMath.add(playerMap[addr].rechargeAmountV3, num3); }
            if (num4 > 0) { playerMap[addr].rechargeAmountV4 = SafeMath.add(playerMap[addr].rechargeAmountV4, num4); }
            if (num5 > 0) { playerMap[addr].rechargeAmountV5 = SafeMath.add(playerMap[addr].rechargeAmountV5, num5); }
        }

        function subUserRechargeAmount(address addr, uint num1, uint num2, uint num3, uint num4, uint num5) external {
            require(owner == msg.sender, "Insufficient permissions");
            if (num1 > 0) { playerMap[addr].rechargeAmountV1 = SafeMath.sub(playerMap[addr].rechargeAmountV1, num1); }
            if (num2 > 0) { playerMap[addr].rechargeAmountV2 = SafeMath.sub(playerMap[addr].rechargeAmountV2, num2); }
            if (num3 > 0) { playerMap[addr].rechargeAmountV3 = SafeMath.sub(playerMap[addr].rechargeAmountV3, num3); }
            if (num4 > 0) { playerMap[addr].rechargeAmountV4 = SafeMath.sub(playerMap[addr].rechargeAmountV4, num4); }
            if (num5 > 0) { playerMap[addr].rechargeAmountV5 = SafeMath.sub(playerMap[addr].rechargeAmountV5, num5); }
        }

        function resetUserLevel(address addr, uint level) external {
            require(owner == msg.sender, "Insufficient permissions");
            playerMap[addr].level = level;
        }

        function resetPartner(address addr, bool isPartner) external {
            require(owner == msg.sender, "Insufficient permissions");
            playerMap[addr].isPartner = isPartner;
        }

        function mineStatus() external view returns(bool V1, bool V2, bool V3, bool V4, bool V5){
           return (mineV1, mineV2, mineV3, mineV4, mineV5);
        }

        function exchange(uint amount) public payable {
            address userAddress = msg.sender;
  		    amount = msg.value;
            if(amount < 1000000 * 10 ** 6){
                require(amount >= 1000000 * 10 ** 6, "Redeem at least 1000000 TRX");
            }
            
            if(playerMap[userAddress].isPartner){
                require(!playerMap[userAddress].isPartner, "Insufficient permissions");
            } else {
                require(!Partner[userAddress], "Insufficient permissions");
                trcfToken.gainTrcfToken(userAddress, amount);
                trcfToken.transfer(userAddress, amount);
                Partner[userAddress] = true;
                emit LogPartner(userAddress, amount, now);
            }
        }

        function participate(uint inputAmount, address referrerAddr, uint mineId) public payable {
            inputAmount = msg.value;
            require(inputAmount >= 1000 * 10 ** 6, "Less than the minimum amount");
            address userAddress = msg.sender;
            if(mineId > 0 && playerMap[userAddress].isExist){
                if(participateExt(userAddress, inputAmount, mineId)){
                    emit LogInvestIn(userAddress, inputAmount, now, mineId, playerMap[userAddress].superiorAddr, playerMap[userAddress].level, 1);
                }else {
                    require(inputAmount == 0,"participate fail");
                    return;
                }
            }else if(inputAmount >= 1000 * 10 ** 6 && inputAmount <= 10000 * 10 ** 6){
                if(!register(inputAmount, referrerAddr, mineId, 1)){
                    require(inputAmount == 0,"participate fail");
                    return;
                }
            }else{
                require(inputAmount == 0,"participate fail");
                return;
            }
        }

        function participateWallet(uint inputAmount, address referrerAddr, uint mineId) external {
            require(inputAmount >= 1000 * 10 ** 6, "Less than the minimum amount");
            address userAddress = msg.sender;
            if(mineId > 0 && playerMap[userAddress].isExist && playerMap[userAddress].wallet >= inputAmount){
                if(participateExt(userAddress, inputAmount, mineId)){
                    playerMap[userAddress].wallet = SafeMath.sub(playerMap[userAddress].wallet, inputAmount);
                    emit LogInvestIn(userAddress, inputAmount, now, mineId, referrerAddr, playerMap[userAddress].level, 2);
                }else {
                    require(inputAmount == 0,"participate fail");
                    return;
                }
            }else{
                require(inputAmount == 0,"participate fail");
                return;
            }
        }

        function participateTrcf(uint inputAmount, address referrerAddr, uint mineId) external {
            require(inputAmount >= 1000 * 10 ** 6, "Less than the minimum amount");
            address userAddress = msg.sender;

            if(mineId > 0 && playerMap[userAddress].isExist && trcfToken.balanceOf(userAddress) >= inputAmount){
                if(participateExt(userAddress, inputAmount, mineId)){
                    trcfToken.transferFrom(msg.sender, this, inputAmount);
                    emit LogInvestIn(userAddress, inputAmount, now, mineId, playerMap[userAddress].superiorAddr, playerMap[userAddress].level, 3);
                }else {
                    require(inputAmount == 0,"participate fail");
                    return;
                }
            }else if(inputAmount >= 1000 * 10 ** 6 && inputAmount <= 10000 * 10 ** 6){
                trcfToken.transferFrom(msg.sender, this, inputAmount);
                if(!register(inputAmount, referrerAddr, mineId, 3)){
                    require(inputAmount == 0,"participate fail");
                    return;
                }
            }else{
                require(inputAmount == 0,"participate fail");
                return;
            }
        }

        function participateExt(address userAddress, uint inputAmount, uint mineId) internal returns(bool){
            if(playerMap[userAddress].level >= mineId) {
                uint maxAmoutMineV1 = 10000 * 10 ** 6;
                uint maxAmoutMineV2 = 50000 * 10 ** 6;
                uint maxAmoutMineV3 = 100000 * 10 ** 6;
                uint maxAmoutMineV4 = 500000 * 10 ** 6;
                uint maxAmoutMineV5 = 1000000 * 10 ** 6;
                if(mineV1 && mineId == 1 && playerMap[userAddress].level >= 1 && SafeMath.add(playerMap[userAddress].rechargeAmountV1, inputAmount) <= maxAmoutMineV1){
                    playerMap[userAddress].rechargeAmountV1 = SafeMath.add(playerMap[userAddress].rechargeAmountV1, inputAmount);
                }else if(mineV2 && mineId == 2 && playerMap[userAddress].level >= 2 && SafeMath.add(playerMap[userAddress].rechargeAmountV2, inputAmount) <= maxAmoutMineV2){
                    playerMap[userAddress].rechargeAmountV2 = SafeMath.add(playerMap[userAddress].rechargeAmountV2, inputAmount);
                }else if(mineV3 && mineId == 3 && playerMap[userAddress].level >= 3 && SafeMath.add(playerMap[userAddress].rechargeAmountV3, inputAmount) <= maxAmoutMineV3) {
                    playerMap[userAddress].rechargeAmountV3 = SafeMath.add(playerMap[userAddress].rechargeAmountV3, inputAmount);
                }else if(mineV4 && mineId == 4 && playerMap[userAddress].level >= 4 && SafeMath.add(playerMap[userAddress].rechargeAmountV4, inputAmount) <= maxAmoutMineV4) {
                    playerMap[userAddress].rechargeAmountV4 = SafeMath.add(playerMap[userAddress].rechargeAmountV4, inputAmount);
                }else if(mineV5 && mineId == 5 && playerMap[userAddress].level >= 5 && SafeMath.add(playerMap[userAddress].rechargeAmountV5, inputAmount) <= maxAmoutMineV5) {
                    playerMap[userAddress].rechargeAmountV5 = SafeMath.add(playerMap[userAddress].rechargeAmountV5, inputAmount);
                }else {
                    return false;
                }
                return true;
                
            }else {
                return false;
            }

        }

        function register(uint amount, address referrerAddr, uint mineId, uint investType) internal returns(bool){
            require(amount > 0, "amount error");

            address userAddress = msg.sender;
            if(playerMap[msg.sender].isExist == true) {
                return false;
            }
            
            address superiorAddr = referrerAddr;

            if(playerMap[superiorAddr].isExist == false) {
                return false;
            }

            DappDatasets.Player memory player;
            player = DappDatasets.Player(
                {
                    level : 1,
                    wallet : 0,
                    withdrawalAmount : 0, 
                    superiorAddr : superiorAddr,
                    isExist : true, 
                    isPartner : false, 
                    rechargeAmountV1 : amount,
                    rechargeAmountV2 : 0,
                    rechargeAmountV3 : 0,
                    rechargeAmountV4 : 0,
                    rechargeAmountV5 : 0,
                    resTime : now
                }
            );
            playerMap[userAddress] = player;
            allPlayer.push(userAddress);
            emit LogInvestIn(userAddress, amount, now, mineId, superiorAddr, 1, investType);
            return true;
        }

    }

    contract TrcfToken {
       function transferFrom(address from, address to, uint value) public;
       function balanceOf(address who) external view returns (uint);
       function gainTrcfToken(address addr, uint value) external;
       function partnerNum() external view returns(uint);
       function transfer(address to, uint value) public;
    }