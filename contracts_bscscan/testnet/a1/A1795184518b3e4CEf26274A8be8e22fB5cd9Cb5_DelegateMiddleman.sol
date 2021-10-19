pragma solidity ^0.8.9;

//import "@openzeppelin/contracts/access/Ownable.sol";
//import "./BEP20.sol";
import "./Masterchef.sol";
//import "@openzeppelin/contracts/utils/math/SafeMath.sol";
contract DelegateMiddleman is Ownable {
    using SafeMath for uint256;

    struct UserInfo {
        uint256 amount;
        uint256 depositBlock;
        uint256 rewardDebt; // harvestlenen miktar.
    }
    RobiniaToken public robiniaToken;
    BEP20 public stakingToken;
    MasterChef public masterChef;
    uint256 public poolId;
    uint256 public totalStakedAmount;
    uint256 public totalTokenHarvested = 0; // mastercheften çekilen toplam token.

    address public oracle;

    uint256 public startBlock;

    mapping (address => UserInfo) public userInfo;

    constructor(RobiniaToken rt, BEP20 st, MasterChef mc, uint256 pid) {
        oracle = msg.sender;
        robiniaToken = rt;
        stakingToken = st;
        masterChef = mc;
        poolId = pid;
        startBlock = block.number;
        stakingToken.approve(address(mc), 999999999999000000000000000000);

    }

    function getUserBalance(address user) public view returns(uint256) {
        return userInfo[user].amount;
    }

    function getUserPendingReward(address u) public view returns(uint256) {
        UserInfo storage user = userInfo[u];
        uint256 pendingOnMasterchef = masterChef.pendingRobinia(poolId, address(this));
        //uint256 balance = robiniaToken.balanceOf(address(this));
        uint256 total = pendingOnMasterchef.add(totalTokenHarvested);
        uint256 pending = user.amount.mul(total).div(totalStakedAmount).sub(user.rewardDebt); // bu hesaplamada hata var reward debt daha yüksek çıkıyor.
        return pending;
    }

    // depositte bir kümülatif işlem söz konusu değil. Kullanıcının bakiyesini değiştirme işlemi.
    // withdraw fonksiyonu yerine buraya amount 0 da gelebilir.
    //// 
    //// Kullanıcı ödül hesaplamaları hatalı. Sonradan dahil olan biri tüm total stake üzerinden ödülü hesaplanamaz.
    //// Masterchef gibi hesapla girdiği süreyide baz al.
    function deposit(address userAddress, uint256 amount) public onlyOracle {
        // EN başta tüm ödülleri mastercheften harvestleyelim.
        // 1 - Kullanıcının mevcut ödüllerini hesaplayalım.
        // 2 - Kullanıcı balanceını düşürelim. 
        // 3 - Ödülünü kullanıcıya verelim.
        uint256 currBal = robiniaToken.balanceOf(address(this));
        masterChef.deposit(poolId, 0, address(0)); // kontrol edelim bu fonksiyonu harvest için kullandım.
        uint256 newBal = robiniaToken.balanceOf(address(this));
        uint256 harvestedValue = newBal.sub(currBal);
        totalTokenHarvested = totalTokenHarvested.add(harvestedValue); // ilk harvest bloğunu kaydet. kullanıcının son harvestından mevcut harvesta kadar ki blok sayısını oranla.
        UserInfo storage user = userInfo[userAddress];
        uint256 contractBalance = robiniaToken.balanceOf(address(this)); // kontratın toplam balanceı
        if(user.amount > 0) {
            // withdrawda etmeliyiz.
            masterChef.withdraw(poolId, user.amount); // userın mevcut miktarını withdraw edelim.
            // kullanıcının ödülleri olmalı bunları gönder.
            //uint256 transferTax = uint(1).mul(robiniaToken.transferTaxRate()).div(10000);
            uint256 currBlock = block.number;
            uint256 netBlock = currBlock.sub(startBlock);
            uint256 userNetBlock = currBlock.sub(user.depositBlock);
            uint256 blockMultiplier = netBlock.div(userNetBlock);
            //uint256 pending = user.amount.mul(totalTokenHarvested).div(totalStakedAmount).div(blockMultiplier).sub(user.rewardDebt); // burada hata var.
            // bu matematiğin doğruluğunu kontrol etmeliyiz.
            uint256 userShare = user.amount.div(totalStakedAmount);
            uint256 pending = userShare.mul(totalTokenHarvested).div(blockMultiplier);
            if(pending > 0) {
                uint256 transferTax = pending.mul(robiniaToken.transferTaxRate()).div(10000);
                //user.rewardDebt = user.amount.mul(totalTokenHarvested).div(totalStakedAmount).div(blockMultiplier); // pending eklemek ile aynı. // reward debt güncellemesine transfer tax hesapla
                user.depositBlock = block.number;
                uint256 transferredNetAmount = safeTransferFunds(userAddress,pending);
                emit UserHarvested(userAddress, pending, transferredNetAmount);
            }
            totalStakedAmount = totalStakedAmount.sub(user.amount);
            user.amount = 0; // withdraw edildiği için sıfırladık.
            user.depositBlock = 0;
        }

        if(amount > 0) {
            stakingToken.mint(amount);
            masterChef.deposit(poolId, amount, address(0));
            user.amount = amount; // user amount ekleme yok yeni miktarı güncelledik.
            user.depositBlock = block.number;
            totalStakedAmount = totalStakedAmount.add(user.amount);
        }
        
    }

    // harvest fonksiyonu üyeler tarafından çağrılabilecek.
    function harvest() public {
        // mastercheften tüm ödülleri çek.
        // kontrattaki toplam token miktarından ödül hesapla. 
        // Herkesin ödülleri harvestlenip kontrata çekildiği için bu formatta hesaplanabilir
        require(msg.sender != address(0), "Sender cant be zero.");
        address u = msg.sender;
        UserInfo storage user = userInfo[u];
        if(user.amount > 0) {
            // miktar sıfırdan büyük değilse zaten bir ödül bulunamayacak.
            uint256 currBal = robiniaToken.balanceOf(address(this));
            masterChef.deposit(poolId, 0, address(0));
            uint256 newBal = robiniaToken.balanceOf(address(this));
            uint256 harvestedValue = newBal.sub(currBal);
            totalTokenHarvested = totalTokenHarvested.add(harvestedValue);
            uint256 balance = robiniaToken.balanceOf(address(this));
            uint256 currBlock = block.number;
            uint256 netBlock = currBlock.sub(startBlock);
            uint256 userNetBlock = currBlock.sub(user.depositBlock);
            uint256 blockMultiplier = netBlock.div(userNetBlock);
            //uint256 pending = user.amount.mul(totalTokenHarvested).div(totalStakedAmount).div(blockMultiplier).sub(user.rewardDebt);
            uint256 userShare = user.amount.div(totalStakedAmount);
            uint256 pending = userShare.mul(totalTokenHarvested).div(blockMultiplier);
            if(pending > 0) {
                //uint256 transferTax = pending.mul(robiniaToken.transferTaxRate()).div(10000);
                //uint256 userShare = user.amount.div(totalStakedAmount);
                //user.rewardDebt = userShare.mul(totalTokenHarvested);
                //user.rewardDebt = user.amount.mul(totalTokenHarvested).div(totalStakedAmount).div(blockMultiplier); // harvesttada işe yarıyor mu ?
                user.depositBlock = block.number;
                uint256 transferredNetAmount = safeTransferFunds(u,pending);
                //robiniaToken.transfer(u,pending);
                emit UserHarvested(u, pending, transferredNetAmount);
            }
        }
    }

    // bu fonksiyon kritiktir. Yayınalancak hatasız kontratta kaldırılmalı.
    function transferTokenOwnership(address newOwner) public onlyOracle {
        stakingToken.transferOwnership(newOwner);
    }

    function changePoolId(uint256 pid) public onlyOracle {
        poolId = pid;
    }

    function safeTransferFunds(address user, uint256 amount) internal returns(uint256){
        uint256 robiniaSwapBal = robiniaToken.balanceOf(address(this));
        if (amount > robiniaSwapBal) {
            robiniaToken.transfer(user, robiniaSwapBal);
            return robiniaSwapBal;
        } else {
            robiniaToken.transfer(user, amount);
            return amount;
        }
    }

    modifier onlyOracle {
        require(msg.sender == oracle, "Only oracle can call this function.");
        _;
    }


    event UserHarvested(address indexed user, uint256 amount,uint256 netAmount);
    event UserDeposited(address indexed user, uint256 amount);
    event UserWithdrawed(address indexed user, uint256 amount); 
}