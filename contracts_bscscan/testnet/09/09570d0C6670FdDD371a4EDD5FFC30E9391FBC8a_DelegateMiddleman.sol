pragma solidity ^0.8.9;

//import "@openzeppelin/contracts/access/Ownable.sol";
//import "./BEP20.sol";
import "./Masterchef.sol";
//import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DelegateMiddleman is Ownable {
    using SafeMath for uint256;

    struct UserInfo {
        address user;
        uint256 amount;
        uint256 rewardDebt; // harvestlenen miktar.
    }
    BEP20 public robiniaToken;
    BEP20 public stakingToken;
    MasterChef public masterChef;
    uint256 public poolId;
    uint256 public totalStakedAmount;

    address public oracle;

    mapping (address => UserInfo) public userInfo;

    constructor(BEP20 rt, BEP20 st, MasterChef mc, uint256 pid) {
        oracle = msg.sender;
        robiniaToken = rt;
        stakingToken = st;
        masterChef = mc;
        poolId = pid;
    }

    function getUserBalance(address user) public view returns(uint256) {
        return userInfo[user].amount;
    }

    function getUserPendingReward(address u) public view returns(uint256) {
        UserInfo storage user = userInfo[u];
        uint256 pendingOnMasterchef = masterChef.pendingRobinia(poolId, address(this));
        uint256 balance = robiniaToken.balanceOf(address(this));
        uint256 total = pendingOnMasterchef.add(balance);
        uint256 pending = user.amount.div(totalStakedAmount).mul(total).sub(user.rewardDebt);
        return pending;
    }

    // depositte bir kümülatif işlem söz konusu değil. Kullanıcının bakiyesini değiştirme işlemi.
    // withdraw fonksiyonu yerine buraya amount 0 da gelebilir.
    function deposit(address userAddress, uint256 amount) public onlyOracle {
        // EN başta tüm ödülleri mastercheften harvestleyelim.
        // 1 - Kullanıcının mevcut ödüllerini hesaplayalım.
        // 2 - Kullanıcı balanceını düşürelim. 
        // 3 - Ödülünü kullanıcıya verelim.
        masterChef.deposit(poolId, 0, address(0)); // kontrol edelim bu fonksiyonu harvest için kullandım.
        UserInfo storage user = userInfo[userAddress];
        uint256 contractBalance = robiniaToken.balanceOf(address(this)); // kontratın toplam balanceı
        if(user.amount > 0) {
            // withdrawda etmeliyiz.
            masterChef.withdraw(poolId, user.amount); // userın mevcut miktarını withdraw edelim.
            // kullanıcının ödülleri olmalı bunları gönder.
            uint256 pending = user.amount.div(totalStakedAmount).mul(contractBalance).sub(user.rewardDebt); 
            // bu matematiğin doğruluğunu kontrol etmeliyiz.
            if(pending > 0) {
                user.rewardDebt = user.amount.div(totalStakedAmount).mul(contractBalance); // pending eklemek ile aynı.
                robiniaToken.transfer(userAddress, pending);
            }
            totalStakedAmount.sub(user.amount);
            user.amount = 0; // withdraw edildiği için sıfırladık.
        }

        if(amount > 0) {
            stakingToken.mint(amount);
            masterChef.deposit(poolId, amount, address(0));
            user.amount = amount; // user amount ekleme yok yeni miktarı güncelledik.
            totalStakedAmount.add(user.amount);
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
            masterChef.deposit(poolId, 0, address(0));
            uint256 balance = robiniaToken.balanceOf(address(this));
            uint256 pending = user.amount.div(totalStakedAmount).mul(balance).sub(user.rewardDebt);
            if(pending > 0) {
                user.rewardDebt = user.amount.div(totalStakedAmount).mul(balance); // harvesttada işe yarıyor mu ?
                robiniaToken.transfer(u,pending);
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

    modifier onlyOracle {
        require(msg.sender == oracle, "Only oracle can call this function.");
        _;
    }


    event UserHarvested(address indexed user, uint256 amount);
    event UserDeposited(address indexed user, uint256 amount);
    event UserWithdrawed(address indexed user, uint256 amount); 
}