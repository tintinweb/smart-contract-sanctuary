// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.10;

/*
                                                                                                                   _____
BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBP+jWNNS.wBB${+6BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BBBBBBBBBBBBBBBBBBBBBBBS1sba1Sm^t{+|e_v_o|+jv^mo1X$S|SBBBBBBBBBBBBBBBBBBBBBBB
BBBBBBBBBBBBBBBBBBN{_rs"|y\_~c;_ZQNy`cNr.ZNRo-"v-;|}+"ov"*BBBBBBBBBBBBBBBBBBB
BBBBBBBBBBBBBBBPtomm^o]++*Sx~RNEv+?"+QBW;+|+L%Nd.uov+1uy`eQ%oEBBBBBBBBBBBBBBB
BBBBBBBBBBBBBBBX~L++-*BBNKx".dBBBN+_$BBBm-|NBBB4`+]6BBN+-vcv.xBBBBBBBBBBBBBBB
BBBBBBBBBBBS"{E0"4BBX-%BBBBK.wBBBX~9BBBBBo-9BBBe_NBBBBX,mBBe-bWaveBBBBBBBBBBB
BBBBBBBBBBBQc;+"[email protected]\\BBBB0:eBBB"vBBBBBBB++BBBx"BBBBN"vBNO",**[email protected]
BBBBBBBBo*7}y_7Qmj|1*|.4BBBN\"$BB*rBBBBBBB"[email protected]"cBBBBe.v|1|ydR*-]o}vZBBBBBBBB
BBBBBBBB%~?SuL;|RBBNdy+;XNBBQ*;6No_RBBBBBK.XBw;{NBBBS^1ebBBBW+"7jSr_KBBBBBBBB
BBBBBBNNNE;XNB0+"$BBBBBP"|QBBNy_o$:ZBBBBBj_Ry^XBBBRt+mBBBBBH"?QBBe_%BBNBBBBBB
BBBBBBo~-\"_|cjo\~9BBBBBNa;eNNNH"+"*BBBBB+++\WBBNj"uBBBBBBS-*o}c*~+1-~oBBBBBB
BBBBBBBRx+SQ$%ayx*\rcXRBBBd+"%BNm\`^[email protected]"[email protected]\?{eXm$Ry"c$BBBBBBB
BBBWjc*|1+;+wBBBBBBQ471174NNo;v*_\"-oBBB{-"*_t*"XNN6L11{PQBBBBBNK";+??vteRBBB
BBBRt~?$BBBE+7$NBBBBBBBRZ_"||r"\@NN4^oN{"OBBm\+Lxx"[email protected]*"mNBNH1_sNBBB
[email protected]*"eS{?|"r|*xaHNBBQ?"QBBBBBBBBBm;\"@BBBBBBBBBW+xNBBQdSt*|\"1v]S]"L$BBBBB
BBBBB}_"[email protected]$4jv***""[email protected];+|||vy9WBBBNHXjv";uBBBBB
BQKox\_;|%BBBBBBBBBBBNH_jBBBBBBBBBBBBBBBBBBBBBBBBBBB+"$NBBBBBBBBBBNw1;_*o%RBB
Ny-;oHNNX\+eZXXXXXXXXXX+"NBBBBBBBBBBBBBBBBBBBBBBBBBB.1XXXXXXXXXXXu+19NQdy_,oB
BB$}\{bE7rr{juuujjjjj]x-+NNb%@NBBBBBBBBBBBBBBB$XSPQB^_]jjjjuuuuuuxrrt6dL"?dBB
BBBbx:"vXRBBBBBBBBBBBNc,t77v+"|HBBBBBBBBBBBBNj;"+L|1|.jBBBBBBBBBBBBRS?;~eRNBB
BBWt.^17XRBBBBBBBBBBBs-+xXyv"+{+"|%NBBBBBBX+^+x";vyw7+.oNBBBBBBBBBB0Zc1_.uNBB
]+"?XQ0X7+"*????????v;"BBBBBRQBmLuRBBBBBBB0y7ONRRBBBBB;"?*???????|"+twRRa?r?a
e*7yONQZ|+cEO$RQNBBBB];BBBBBBBN1%BBBBBBBBBBB4|BBBBBBBR~oBBBBNR0$bwv+*XQNm}1+t
BBNo_^+c%NBBBBBBBBBBBo~QBBBBBBa*BBBBBBBBBBBBN|PBBBBBBb-XBBBBBBBBBBBNw*+"vSWBB
BB%[email protected]]mBBBBBX|BBBBBBP.mBBBBBBBBBBBBBNQo+ZNBB
BBRv-+1y$BBBBBBROwo]L\`SBBBBBd\BBBRoxe$u7oRNBN+WBBBBBj`[email protected]\"vRBBB
No^+dBH}++Lvv???L{[email protected]]@@+BBBBBd_e$mZyx?****?L+ru$BdSOBB
m"+S$BNbr+w$NBBBBBBBB$u.|NBBBB+|+veXbNBNHXy*+++BBBBB+:SRBNBBBBBBNbo"*[email protected]"wB
BBRX]v\"yNBBBBBBBBbsr\]Z_emessx"+]t]eyyye{7x"+xsseK6^Xx\|e$BBBBBBBBRx;|*?eOBB
BBBBE-"KBBBBBN0o|+L9NBBBX`+]yadQmtts\@Bm1]LtORmSe]" mBBBQX?\*ZQBBBBBNPrZBBBBB
BBBBBRy-"|7aa1+tmNBBBBBBN7cN$Eoyuu?_.LK1-_Ljuyo6RN|+BBBBBBBNPc\|oS7|"|ybBBBBB
BBBBBQ+;004"[email protected]`|eoej?+;` _*, .;+?jeee+`+NBBBBBBBBBBK++ERbjNBBBBBB
BBBBBv,KBBB"cBBBBBBBBBBZ"vt_]yyu?1|_LmZm*^|rcyyy{_ox"9BBBBBBBBBBorBBBPeNBBBBB
[email protected]+voSSe-aBBBBBBBBO++6BQv"aj]e]+7*+x"vcruy{jo;eBBZ"|@[email protected]~oyxv"6BBBBB
BBBBBBBBN0L.omb$RNBRx"eNBBBNe+\?+_;"+|*r"^_:1v+rXBBBBR{;uNBNQ$bKP"uSEORBBBBBB
BBBBBBBBBBQO+^????|:+WBBBBBBBQ7||[email protected]`+|rrtNBBBBBBBb"_*????;?9BBBBBBBBBBB
BBBBBBBBBBBQ^SNBBBZ-KBBBBBBBBx"RBBL"BBBBQ_uBNH~uNBBBBBBNw-%BBBByyBBBBBBBBBBBB
BBBBBBBBBBBX`QBBBB|+BBBBBBBB%~EBBB"tBBBBB|rBBBe:KBBBBBBBN"cBBBBWLBBBBBBBBBBBB
BBBBBBBBBBBv-}tc7?-eBBBBBBBR"7BBBd-9BBBBBe~RBBB1"NBBBBBBB]~vvcx}"NBBBBBBBBBBB
BBBBBBBBBBBR$RNBBv-oSoeu]{c"+NBBB};NBBBBBW,oBBBR;"7x][email protected]
BBBBBBBBBBBBBBBBBEyoS+_ZwPm^{BBBB+vBBBBBBB+*BBBB*"m6wZ"SoeSNBBBBBBBBBBBBBBBBB
BBBBBBBBBBBBBBBBBBBBBt"BBBB;sBBBB1+NBBBBBR"cBBBBv+BBBN*NBBBBBBBBBBBBBBBBBBBBB
BBBBBBBBBBBBBBBBBBBBBx"BBBN^uBBBB$^jBBBBNv"RBBBBv"BBBN|BBBBBBBBBBBBBBBBBBBBBB
BBBBBBBBBBBBBBBBBBBBB{_o{xc.yBBN6t;,mBBNa-"sdNBBc;vvxy\BBBBBBBBBBBBBBBBBBBBBB
[email protected]@-to|^|o$L"[email protected]_s$o1"vZ*{BNmoXBBBBBBBBBBBBBBBBBBBBBB
BBBBBBBBBBBBBBBBBBBBBBBBBB01LX4-yNN9-vN\~KBBxvK]\SBBBBBBBBBBBBBBBBBBBBBBBBBBB
BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB]:xxuy-t1S*1?+RBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
[email protected]BBBBBBBBBBBBB

______  ______  _____                   ____             _____   ______   _______    _______     _______      _____\    \  _____           _____
\     \|\     \|\    \              ____\_  \__     _____\    \_|\     \  \      \  /      /|   |\      \    /    / |    ||\    \         |\    \
 |     |\|     |\\    \            /     /     \   /     /|     |\\     \  |     /|/      / |   | \      \  /    /  /___/| \\    \         \\    \
 |     |/____ /  \\    \          /     /\      | /     / /____/| \|     |/     //|      /  |___|  \      ||    |__ |___|/  \\    \         \\    \
 |     |\     \   \|    | ______ |     |  |     ||     | |____|/   |     |_____// |      |  |   |  |      ||       \         \|    | ______  \|    | ______
 |     | |     |   |    |/      \|     |  |     ||     |  _____    |     |\     \ |       \ \   / /       ||     __/ __       |    |/      \  |    |/      \
 |     | |     |   /            ||     | /     /||\     \|\    \  /     /|\|     ||      |\\/   \//|      ||\    \  /  \      /            |  /            |
/_____/|/_____/|  /_____/\_____/||\     \_____/ || \_____\|    | /_____/ |/_____/||\_____\|\_____/|/_____/|| \____\/    |    /_____/\_____/| /_____/\_____/|
|    |||     | | |      | |    ||| \_____\   | / | |     /____/||     | / |    | || |     | |   | |     | || |    |____/|   |      | |    |||      | |    ||
|____|/|_____|/  |______|/|____|/ \ |    |___|/   \|_____|    |||_____|/  |____|/  \|_____|\|___|/|_____|/  \|____|   | |   |______|/|____|/|______|/|____|/
                                   \|____|               |____|/                                                  |___|/
*/

import "./SafeMath.sol";
import "./Erc20.sol";

// Basic ERC-20 used for testing
contract BasicErc20 is Erc20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    string public name = "Basic";
    string public symbol = "BSC";
    uint8 public decimals;

    constructor(uint8 _decimals, uint256 _supply) public {
        decimals = _decimals;

        _totalSupply = _supply;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address owner) public override view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(
        address owner,
        address spender
    )
    public override
    view
    returns (uint256)
    {
        return _allowed[owner][spender];
    }

    /**
    * @dev Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) public override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public override returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    )
    public override
    returns (bool)
    {
        require(value <= _allowed[from][msg.sender]);

        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    )
    public
    returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    )
    public
    returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
    * @dev Transfer token for a specified addresses
    * @param from The address to transfer from.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function _transfer(address from, address to, uint256 value) internal {
        require(value <= _balances[from]);
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }
}