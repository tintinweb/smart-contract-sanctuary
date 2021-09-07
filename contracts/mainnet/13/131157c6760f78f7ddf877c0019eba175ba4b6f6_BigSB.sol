// SPDX-License-Identifier: UNLICENSE

// ANDRZEJU! NIE DENERWUJ SIĘ!

/**
Apes Together Strong!

About BigShortBets DeFi project:

We are creating a social&trading p2p platform that guarantees encrypted interaction between investors.
Logging in is possible via a cryptocurrency wallet (e.g. Metamask).
The security level is one comparable to the Tor network.

https://bigsb.io/ - Our Tool
https://bigshortbets.com - Project&Team info

Video explainer:
https://youtu.be/wbhUo5IvKdk

Idea: 
https://bigshortbets.com/idea/

The stock exchange is an emanation of the highest form of market freedom related to the natural and inalienable right of every human being to possess.

It is the freedom – the basic and most precious good, which allows us (people who take responsibility for their actions) to decide about property in a free and unhindered way, regardless of our internal or external motivation.

This is how the stock exchange was understood in the early 17th century, when the first modern stock exchange, established in 1611 by Dutch merchants in Amsterdam, made its debut. It was established by Dutch merchants in Amsterdam. As Joseph de la Vega, speculator, investor, merchant and author of Confusion de Confusiones 1688, the oldest book on speculation published in 1688, wrote:

“Among the plays which men perform in taking different parts in this magnificent world theatre, the greatest comedy is played at the Exchange. There, in an inimitable fashion, the speculators excel in tricks, they do business and find excuses wherein hiding-places, concealment of facts , quarrels, provocations, mockery, idle talk, violent desires, collusion, artful deception, betrayals, cheatings, and even the tragic end are to be found.”

In the early days of the stock market, trading was based on mutual trust – (Only since he published in 1688, i.e. he must have noticed much earlier what he noticed, does the statement “in the early days of the stock market, trading was based on mutual trust” have anything to do with the truth at all? Are we talking about beginnings in the sense of the first few minutes? Because de la Vega proves that the dirty games started right from the beginning).

Over time, especially since the end of the 1920s, when Wallstreet had its big crash, trade gradually began to be subject to various regulations, the aim of which was, above all, to protect small investors and level their chances in “clashing” with big “fish”, or “whales” as we call them now. What should be regulated by the market itself, began to be the domain of officials who, despite their best intentions, rather than helping small investors, harmed them more, gradually increasing the advantage of Wallstret over Mainstreet. This led to a clear restriction of freedom of speech – from now on you had to be careful with whom you spoke, what you spoke about and how you spoke. All this to avoid being accused of manipulation and acting against the new law.

The short squeeze action on GameStop carried out by the Reddit community connected to the Wallstreetbets forum made us realise that fair play is a fantasy and market reality proves that there are equal and more equal investors. Thus, the head of a hedge fund with X investors under him, i.e. being in “agreement” with them or making investment decisions on their behalf, is better treated than investors acting independently on their own account and on their behalf, supporting each other and consulting their investment movements with each other.

Supervisory authorities such as ESMA (the European Securities and Markets Authority) criticised the action on GameStop, but focused their criticism on the weakest and smallest players, who were, after all, acting lawfully in exercising their rights to have opinions and to share them with other free people.

In our opinion, this approach violates the natural and inalienable right to decide on one’s own property. It has emerged that private investors exercising their fundamental right to have an opinion and act accordingly on the market are being restricted, their freedom of expression curtailed and their perfectly legal activities demonised. In the cases cited above, it was the fund that acted to the detriment of small investors by manipulating GameStop’s shares (and it was by no means the first such manipulation). In the face of such ‘tricks’, small investors do not stand much of a chance against the rich whales of Wall Street, especially when the bodies set up to protect the weak actually favour the strong, giving their enormous capital an advantage.

For this reason, the idea was born to build a decentralised and encrypted tool in which users’ privacy would be protected in the name of the values that belong to us naturally, that we all possess and that we consider to be the greatest good. To achieve this, we must take risks and oppose oppressive, unfair and unjust laws that restrict freedom.

A final, but equally important advantage is the size of the capital and this can only be levelled in the way it was with the last action on GameStop – it must result from coordinated efforts by individual investors. In response to the above situation, we are building a “bottom-up” tool that enables encrypted and fully secure communication between users based on a token and blockchain network. The free exchange of data in the information market will allow the same or even faster access to news than from giants such as Reuters and Bloomberg, thus breaking their monopoly on first-hand knowledge.

BigShortBets tools will allow to coordinate the activities of groups of smaller investors, which in turn will contribute to reducing the advantage of investment funds and their more effective play.

Zaorski, You Son of a bitch I’m in …
*/

import "./owned.sol";
import "./interfaces.sol";

pragma solidity 0.8.7;

// BigShortBets.com deflationary token
contract BigSB is IERC20, Owned {
    // You SOB, I'm in!
    constructor(address _owner) {
        (uint256 rAmount, , , , , , ) = _getValues(INITIAL_SUPPLY);
        _rOwned[_owner] = rAmount;
        emit Transfer(ZERO, _owner, INITIAL_SUPPLY);
        owner = _owner;
    }

    string public constant name = "BigShortBets";
    string public constant symbol = "BigSB";
    uint8 public constant decimals = 18;

    uint256 private constant MAX = type(uint256).max;
    uint256 private constant INITIAL_SUPPLY = 100_000_000 * (10**18);
    uint256 private constant BURN_STOP_SUPPLY = INITIAL_SUPPLY / 10;
    uint256 private _tTotal = INITIAL_SUPPLY;
    uint256 private _rTotal = (MAX - (MAX % INITIAL_SUPPLY));
    uint256 private _tFeeTotal;

    address private constant ZERO = address(0);
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) public override allowance;

    mapping(address => bool) public isFeeFree;

    mapping(address => bool) public isExcluded;
    address[] private _excluded;

    // ERC20 totalSupply
    function totalSupply() external view override returns (uint256) {
        return _tTotal;
    }

    /// Total fees collected
    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

    // ERC20 balanceOf
    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        if (isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    // ERC20 transfer
    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    // ERC20 approve
    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    // ERC20 transferFrom
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        uint256 amt = allowance[sender][msg.sender];
        require(amt >= amount, "ERC20: transfer amount exceeds allowance");
        // reduce only if not permament allowance (uniswap etc)
        if (amt < MAX) {
            allowance[sender][msg.sender] -= amount;
        }
        _transfer(sender, recipient, amount);
        return true;
    }

    // ERC20 increaseAllowance
    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            allowance[msg.sender][spender] + addedValue
        );
        return true;
    }

    // ERC20 decreaseAllowance
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        require(
            allowance[msg.sender][spender] >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        _approve(
            msg.sender,
            spender,
            allowance[msg.sender][spender] - subtractedValue
        );

        return true;
    }

    // ERC20 burn
    function burn(uint256 amount) external {
        require(msg.sender != ZERO, "ERC20: burn from the zero address");
        (uint256 rAmount, , , , , , ) = _getValues(amount);
        _burn(msg.sender, amount, rAmount);
    }

    // ERC20 burnFrom
    function burnFrom(address account, uint256 amount) external {
        require(account != ZERO, "ERC20: burn from the zero address");
        require(
            allowance[account][msg.sender] >= amount,
            "ERC20: burn amount exceeds allowance"
        );
        allowance[account][msg.sender] -= amount;
        (uint256 rAmount, , , , , , ) = _getValues(amount);
        _burn(account, amount, rAmount);
    }

    /**
        Burn tokens into fee (aka airdrop)
        @param tAmount number of tokens to destroy
     */
    function reflect(uint256 tAmount) external {
        address sender = msg.sender;
        require(
            !isExcluded[sender],
            "Excluded addresses cannot call this function"
        );
        (uint256 rAmount, , , , , , ) = _getValues(tAmount);
        _rOwned[sender] -= rAmount;
        _rTotal -= rAmount;
        _tFeeTotal += tAmount;
    }

    /**
        Reflection amount for given amount of token, can deduct fees
        @param tAmount number of tokens to transfer
        @param deductTransferFee true or false
        @return amount reflection amount
     */
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        external
        view
        returns (uint256 amount)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            //rAmount
            (amount, , , , , , ) = _getValues(tAmount);
        } else {
            //rTransferAmount
            (, amount, , , , , ) = _getValues(tAmount);
        }
    }

    /**
        Calculate number of tokens by current reflection rate
        @param rAmount reflected amount
        @return number of tokens
     */
    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    /**
        Internal approve function, emit Approval event
        @param _owner approving address
        @param spender delegated spender
        @param amount amount of tokens
     */
    function _approve(
        address _owner,
        address spender,
        uint256 amount
    ) private {
        require(_owner != ZERO, "ERC20: approve from the zero address");
        require(spender != ZERO, "ERC20: approve to the zero address");

        allowance[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    /**
        Internal transfer function, calling feeFree if needed
        @param sender sender address
        @param recipient destination address
        @param tAmount transfer amount
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        require(sender != ZERO, "ERC20: transfer from the zero address");
        require(recipient != ZERO, "ERC20: transfer to the zero address");
        if (tAmount > 0) {
            if (isFeeFree[sender]) {
                _feeFreeTransfer(sender, recipient, tAmount);
            } else {
                (
                    uint256 rAmount,
                    uint256 rTransferAmount,
                    uint256 rFee,
                    uint256 rBurn,
                    uint256 tTransferAmount,
                    uint256 tFee,
                    uint256 tBurn
                ) = _getValues(tAmount);

                _rOwned[sender] -= rAmount;
                if (isExcluded[sender]) {
                    _tOwned[sender] -= tAmount;
                }
                _rOwned[recipient] += rTransferAmount;
                if (isExcluded[recipient]) {
                    _tOwned[recipient] += tTransferAmount;
                }

                _reflectFee(rFee, tFee);
                if (tBurn > 0) {
                    _reflectBurn(rBurn, tBurn, sender);
                }
                emit Transfer(sender, recipient, tTransferAmount);
            }
        } else emit Transfer(sender, recipient, 0);
    }

    /**
        Function provide fee-free transfer for selected addresses
        @param sender sender address
        @param recipient destination address
        @param tAmount transfer amount
     */
    function _feeFreeTransfer(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (uint256 rAmount, , , , , , ) = _getValues(tAmount);
        _rOwned[sender] -= rAmount;
        if (isExcluded[sender]) {
            _tOwned[sender] -= tAmount;
        }
        _rOwned[recipient] += rAmount;
        if (isExcluded[recipient]) {
            _tOwned[recipient] += tAmount;
        }
        emit Transfer(sender, recipient, tAmount);
    }

    /// reflect fee amounts in global values
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal -= rFee;
        _tFeeTotal += tFee;
    }

    /// reflect burn amounts in global values
    function _reflectBurn(
        uint256 rBurn,
        uint256 tBurn,
        address account
    ) private {
        _rTotal -= rBurn;
        _tTotal -= tBurn;
        emit Transfer(account, ZERO, tBurn);
    }

    /// calculate reflect values for given transfer amount
    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 rBurn,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tBurn
        )
    {
        tFee = tAmount / 100; //1% transfer fee
        tTransferAmount = tAmount - tFee;
        if (_tTotal > BURN_STOP_SUPPLY) {
            tBurn = tAmount / 200; //0.5% burn fee
            if (_tTotal < BURN_STOP_SUPPLY + tBurn) {
                tBurn = _tTotal - BURN_STOP_SUPPLY;
            }
            tTransferAmount -= tBurn;
        }
        uint256 currentRate = _getRate();
        rAmount = tAmount * currentRate;
        rFee = tFee * currentRate;
        rTransferAmount = rAmount - rFee;
        if (tBurn > 0) {
            rBurn = tBurn * currentRate;
            rTransferAmount -= rBurn;
        }
    }

    function getRate() external view returns (uint256) {
        return _getRate();
    }

    /// calculate current reflect rate
    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    /// calculate current token supply
    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        uint256 i;
        for (i; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply -= _rOwned[_excluded[i]];
            tSupply -= _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    /// internal burn function
    function _burn(
        address account,
        uint256 tAmount,
        uint256 rAmount
    ) private {
        require(
            _rOwned[account] >= rAmount,
            "ERC20: burn amount exceeds balance"
        );
        _rOwned[account] -= rAmount;
        if (isExcluded[account]) {
            require(
                _tOwned[account] >= tAmount,
                "ERC20: burn amount exceeds balance"
            );

            _tOwned[account] -= tAmount;
        }
        _reflectBurn(rAmount, tAmount, account);
    }

    //
    // Rick mode
    //

    /**
        Add address that will not pay transfer fees
        @param user address to mark as fee-free
     */
    function addFeeFree(address user) external onlyOwner {
        isFeeFree[user] = true;
    }

    /**
        Remove address form privileged list
        @param user user to remove
     */
    function removeFeeFree(address user) external onlyOwner {
        isFeeFree[user] = false;
    }

    /**
        Exclude address form earing transfer fees
        @param account address to exclude from earning
     */
    function excludeAccount(address account) external onlyOwner {
        require(!isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        isExcluded[account] = true;
        _excluded.push(account);
    }

    /**
        Include address back to earn transfer fees
        @param account address to include
     */
    function includeAccount(address account) external onlyOwner {
        require(isExcluded[account], "Account is already included");
        uint256 i;
        for (i; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    /**
        Take ETH accidentally send to contract
    */
    function withdrawEth() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    /**
        Take any ERC20 sent to contract
        @param token token address
    */
    function withdrawErc20(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "Nothing to withdraw");
        // use broken IERC20
        IUsdt(token).transfer(owner, balance);
    }
}

//rav3n_pl was here

//This is fine!