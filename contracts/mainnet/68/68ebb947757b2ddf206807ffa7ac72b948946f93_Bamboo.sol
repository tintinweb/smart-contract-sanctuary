// File: contracts/Bamboo.sol

pragma solidity ^0.8.0;

import "FlattenBambooPrefix.sol";

/**
 * @title Bamboo
 * 
 * MMMMMMMMMMMMMMMMMWWWWNNNXXKK0OOOxl;;;:ldk0XWMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMWNNNNNNNNNNNNNNNNNNN0xl;'''.';cd0NWMMMMMMMMMMMM
 * MMMMMMMMMMN0k0XNNNNNXXXXXXXXXXNNNXXKOxc'.....,cd0NMMMMMMMMMM
 * MMMMMMMWXkxxkKXNNXXXKK0KKKK0KKKXKKKKKOc'.....',';lkXWMMMMMMM
 * MMMMMMXx::x0XXXXXKKK00OO00OOO0K0OOkkkd;......''','';xXMMMMMM
 * MMMMWO:',okO000000O00OOkkxxkkkkxodxkxl,.....','''....:OWMMMM
 * MMMNx,.'cxddxkOOOkxxxkOkkxxkxdl:'':ooc,.....',,.......'dXMMM
 * MMKo;..:dxlcdxkOxl;:ldO000000xdl,':odc'.....,;;,....''',oXMM
 * MXl''.;dkxl:ldxxo:',cox0KKXXK0Okdddxxc'.....,;,',,...''''lXM
 * Nx,''.:xkdc;cokkOkxxxxO0KKK0OOO000Okd:.....',,'',,'......'dN
 * O:','.'coo:,;lxkOO00KKKKOdc:,;cdO0Oxl,.....',,'',,'.......;O
 * o;,,;'..':c::ldxkkxkOKKOxc'..';cxxdo:'.....'',,,,,'........c
 * ;,,,;,...;oooodddxxxxkkxdl;,,;:clccc:,'...'';okdl;...''....'
 * ..,,,,...,oxxxxxxxxxdooolccccccc::::;,'...';dKXX0d;........'
 * ..,,,,....;oxxkOOkkxddollllllccc::cc;''...,lOKXXXKd;........
 * ..',,;'...,oxkkOO0OOkxxdooolllllllol;''...;dKXXXXKkc,.......
 * ..';;:,..'ckOOOO0000OOOkxddooooooooc,''..';dKXXXXKOo;......'
 * ;.':::,..,oO0000KXXXKK00Okkxddddddoc,'''.':dO0KKKK0x:'.....:
 * o..,:;'..'oOK0O0KXXKKKK000Okxdddddo:,''..,:oxkO0K0Od;.....,x
 * K;..;,'..:x0XK00KXXXKK000Okxxdddxxo:'''.';cdkO000Oko;....'lK
 * Wk,.,;,,,:d0KXKKXXXXKK00Okkxxxxxxdl;'''.';okO000Okxl;....,OW
 * MWO:;;,,;:lkKKXXXXXXKK0kxxkkkkkxxdl,''',:lxkOO0Okxo:,'..,kWM
 * MMW0l:,,;:cdOKK000KK0kxxkkkkOkkkxdl,';cdkOO0OOOkxl;'...;OWMM
 * MMMWKd:,,;;:dkOO00K0OkkOOOkkkkkkkxl::dO000000Okxdc,'..c0WMMM
 * MMMMMNOc,'..;oxkO0OO00KK0000OOOOkxxxO0KK000Okkxddc,,lONMMMMM
 * MMMMMMWXx:...;oxkkkOO00KKKKKKXXXK0KXKK000OkkxxdddllkXMMMMMMM
 * MMMMMMMMMXOo;,:odxxxkkO000KKKKKKKXXNXK0OkxxxdddxOKNWMMMMMMMM
 * MMMMMMMMMMMWKkolodddddxxkkkkkkkkOKXXXK0OkxddxOKNWMMMMMMMMMMM
 * MMMMMMMMMMMMMMWXKKOkxdddddxxxxxxxkkOkkOOOO0KNWMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMWNXKOkxdddddddddxkO0KXNWMMMMMMMMMMMMMMMMMM
 * 
 * References
 * 
 * - https://github.com/OpenZeppelin/openzeppelin-contracts
 */
contract Bamboo is ERC20 {
    event Sacrifice(uint256 amount_);

    /**
     * @dev Initializes the contract.
     */
    constructor () ERC20("Bamboo", "BMB") {
        ERC20._mint(_msgSender(), (10 ** 15) * (10 ** 18));
        sacrifice(5 * (10 ** 14) * (10 ** 18)); // :)
    }

    /**
     * @dev Same as `burn`, but emitted.
     */
    function sacrifice(uint256 amount) public virtual {
        transfer(0x000000000000000000000000000000000000dEaD, amount);
        emit Sacrifice(amount); // WHOOOOOOOOOOOOOOOA
    }

    /**
     * @dev Same as `burnFrom`, but emitted.
     */
    function sacrificeFrom(address account, uint256 amount) public virtual {
        transferFrom(account, 0x000000000000000000000000000000000000dEaD, amount);
        emit Sacrifice(amount); // WHOOOOOOOOOOOOOOOA
    }

    /**
     * @dev Approves token to max value.
     */
    function approve(address spender) public virtual returns (bool) {
        _approve(_msgSender(), spender, type(uint256).max);
        return true;
    }
}