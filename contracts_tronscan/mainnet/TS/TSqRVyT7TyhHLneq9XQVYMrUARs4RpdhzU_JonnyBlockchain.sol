//SourceUnit: TestTRX.sol

pragma solidity ^0.5.0;
/*
------------------------------------
 Jonny Blockchain (R)
 Website :  https://jonnyblockchain.com
------------------------------------
 v. 0.27 => 1.0
*/
contract JonnyBlockchain {
    using SafeMath for uint;
    uint public totalAmount;
    uint public totalReturn;
    uint public totalAffiliateReturn;
    uint public leftOver;
    uint private minDepositSize = 100000000;
    uint private minWithdrawalSize = 10000000;
    uint private returnMultiplier = 125;
    uint public productTotal;
    uint public productTransferred;
    uint private productTransferThreshold = 500;
    address payable owner;

    struct User {
        address sponsor;
        uint amount;
        uint returned;
        uint withdrawn;
        uint affiliateReturn;
    }

    struct Asset {
        address userAddress;
        uint amount;
        uint returned;
    }

    mapping(address => User) public users;
    Asset[] public assets; // TODO shall we change it to private ??

    event Signup(address indexed userAddress, address indexed _referrer);
    event Deposit(address indexed userAddress, uint amount, uint totalAmount, uint totalReturn);
    event OwnerDeposit(address indexed userAddress, uint amount, uint leftOver, uint effectiveAmount, uint balance, uint totalAmount, uint totalReturn, uint totalAffiliateReturn);
    event Invested(address indexed userAddress, uint amount);
    event Reinvested(address indexed userAddress, uint amount, uint withdrawn, uint totalAmount, uint totalReturn, uint totalAffiliateReturn);
    event RefBonus(address indexed userAddress, address indexed referral, uint indexed level, uint amount);
    event ReinvestAttempt(address indexed userAddress, uint available, uint balance);
    event ReinvestAttemptFailed(address indexed userAddress, uint amount, uint available, uint balance);
    event ProductPurchase(address indexed userAddress, uint amount, uint productType);
    event ProductTransfer(uint accumulated, uint productTransferred);
    event AssetClosed(address indexed userAddress, uint index, uint amount);

    event E1(uint i, uint asset_amount, uint maxReturn, uint remainder, address indexed asset_userAddress, uint asset_returned, uint user_amount, uint user_returned, uint user_affiliateReturn, address indexed user_sponsor, uint user_withdrawn);
    event E2(uint i, address indexed asset_userAddress, uint commission, uint remainder, uint totalAffiliateReturn, uint asset_returned, uint user_returned);
    event E3(uint i, address indexed asset_userAddress, uint totalAffiliateReturn, uint user_affiliateReturn, uint user_returned, uint remainder);

    /**
     * owner only access
     */
    modifier onlyOwner() {
        if (msg.sender == owner) {
            _;
        }
    }

    constructor() public {
        owner = msg.sender;
    }

    function() external payable {
    }

    /**
     * deposit handler function with no address
     * distributing returns amongst active assets
     */
    function ownerDeposit() public payable {

        // calculating available balance

        uint amount = msg.value + leftOver;
        uint totalAmountLocal = totalAmount;
        uint given = 0;
        totalReturn += msg.value;
        emit OwnerDeposit(msg.sender, msg.value, leftOver, amount, address(this).balance, totalAmountLocal, totalReturn, totalAffiliateReturn);

        // looping commissions

        for (uint i = 0; i < assets.length; i++) {
            if (0 >= amount) {
                return;
            }
            Asset storage asset = assets[i];
            User storage user = users[asset.userAddress];
            uint maxReturn = asset.amount.mul(returnMultiplier).div(100);
            uint remainder = maxReturn - asset.returned;

//            emit E1(i, asset.amount, maxReturn, remainder, asset.userAddress, asset.returned, user.amount, user.returned, user.affiliateReturn, user.sponsor, user.withdrawn);

            // filling the deal with affiliate distributeReturns

            if (user.affiliateReturn < remainder) {

                // using affiliate commission for fulfilling the order

                remainder -= user.affiliateReturn;
                totalAffiliateReturn -= user.affiliateReturn;
                asset.returned += user.affiliateReturn;
                user.returned += user.affiliateReturn;
                user.affiliateReturn = 0;

                // adding the commission
                uint commission = totalAmountLocal > 0 ? (amount * asset.amount / totalAmountLocal).min(remainder) : 0;
                asset.returned += commission;
                user.returned += commission;
                given += commission;

//                emit E2(i, asset.userAddress, commission, remainder, totalAffiliateReturn, asset.returned, user.returned);

                // closing the deal

                if (asset.returned >= maxReturn) {
                    closeAsset(i--);
                }

            } else {

                // fully closing the deal with the affiliate Returns

                totalAffiliateReturn -= remainder;
                user.affiliateReturn -= remainder;
                user.returned += remainder;

                emit E3(i, asset.userAddress, totalAffiliateReturn, user.affiliateReturn, user.returned, remainder);

                closeAsset(i--);
            }
        }

        leftOver = amount.sub(given);
    }

    /**
     * closes the active asset by removing it from the assets array;
     */
    function closeAsset(uint index) private onlyOwner {
        emit AssetClosed(assets[index].userAddress, index, assets[index].amount);
        totalAmount -= assets[index].amount;
        if (index < assets.length - 1) {
            assets[index] = assets[assets.length - 1];
        }
        assets.pop();
    }

    /**
     * deposit handler function
     */
    function deposit(address _affAddr) public payable {
        if (msg.sender == owner) {
            ownerDeposit();
            return;
        }

        uint depositAmount = msg.value;

        require(depositAmount >= minDepositSize, "There's a minimum deposit amount of 100 TRX");
        User storage user = users[msg.sender];

        // registering a new user

        if (user.amount == 0) {
            user.sponsor = _affAddr != msg.sender && _affAddr != address(0) && users[_affAddr].amount > 0 ? _affAddr : owner;
            emit Signup(msg.sender, user.sponsor);
        }

        // creating an asset

        assets.push(Asset({
            userAddress: msg.sender,
            amount: depositAmount,
            returned: 0
        }));

        // updating counters

        user.amount += depositAmount;
        totalAmount += depositAmount;

        // distributing commissions

        uint affiliateReturnPaid = distributeAffiliateCommissions(depositAmount, user.sponsor);
        uint invested = depositAmount.sub(affiliateReturnPaid);
        totalAffiliateReturn += affiliateReturnPaid;
        owner.transfer(invested);
        emit Invested(msg.sender, invested);
        emit Deposit(msg.sender, depositAmount, totalAmount, totalReturn);
    }

    /**
     * distributes 4 level affiliate commissions: 5%, 3%, 1% and 1% returning the total amount given
     */
    function distributeAffiliateCommissions(uint depositAmount, address _sponsor) private returns(uint) {
        address _affAddr1 = _sponsor;
        address _affAddr2 = users[_affAddr1].sponsor;
        address _affAddr3 = users[_affAddr2].sponsor;
        address _affAddr4 = users[_affAddr3].sponsor;
        uint _affiliateReturn;
        uint given = 0;

        if (_affAddr1 != address(0) && _affAddr1 != owner) {
            _affiliateReturn = depositAmount.mul(5).div(100);
            given += _affiliateReturn;
            users[_affAddr1].affiliateReturn += _affiliateReturn;
            emit RefBonus(_affAddr1, msg.sender, 1, _affiliateReturn);
        }

        if (_affAddr2 != address(0) && _affAddr2 != owner) {
            _affiliateReturn = depositAmount.mul(3).div(100);
            given += _affiliateReturn;
            users[_affAddr2].affiliateReturn += _affiliateReturn;
            emit RefBonus(_affAddr2, msg.sender, 2, _affiliateReturn);
        }

        if (_affAddr3 != address(0) && _affAddr3 != owner) {
            _affiliateReturn = depositAmount.mul(1).div(100);
            given += _affiliateReturn;
            users[_affAddr3].affiliateReturn += _affiliateReturn;
            emit RefBonus(_affAddr3, msg.sender, 3, _affiliateReturn);
        }

        if (_affAddr4 != address(0) && _affAddr4 != owner) {
            _affiliateReturn = depositAmount.mul(1).div(100);
            given += _affiliateReturn;
            users[_affAddr4].affiliateReturn += _affiliateReturn;
            emit RefBonus(_affAddr4, msg.sender, 4, _affiliateReturn);
        }

        return given;
    }

    /**
     * antispam function name
     */
    function reinvest(uint amountOverride) public returns(uint) {
        address payable recipient = msg.sender;
        User storage user = users[recipient];
        require(recipient != address(0), "Incorrect recipient address");
        uint available = user.returned - user.withdrawn;
        if (amountOverride > 0) {
            available = available.min(amountOverride);
        }
        emit ReinvestAttempt(recipient, available, address(this).balance);
        require(available >= minWithdrawalSize, "Payment size is less that minimum payment size");

        if (address(this).balance > 0) {
            uint amount = available.min(address(this).balance);
            user.withdrawn = user.withdrawn.add(amount);

            if (recipient.send(amount)) {
                emit Reinvested(recipient, amount, user.withdrawn, totalAmount, totalReturn, totalAffiliateReturn);
            } else {
                user.withdrawn = user.withdrawn.sub(amount);
                emit ReinvestAttemptFailed(recipient, amount, available, address(this).balance);
            }
        }

        return user.withdrawn;
    }

    /**
     * serves TRON product purchase e.g. adding an exchange or an access to a specific website feature
     */
    function productPurchase(uint productType) public payable {
        emit ProductPurchase(msg.sender, msg.value, productType);
        productTotal += msg.value;
        uint accumulated = productTotal - productTransferred;
        if (accumulated >= productTransferThreshold) {
            owner.transfer(accumulated);
            productTransferred += accumulated;
            emit ProductTransfer(accumulated, productTransferred);
        }
    }
}

library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0);
        uint c = a / b;
        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        uint c = a - b;
        return c;
    }
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }
    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }
    function max(uint a, uint b) internal pure returns (uint) {
        return a > b ? a : b;
    }
}