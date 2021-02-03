// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WrappedToken is ERC20, Ownable {
    event Burn(address indexed _sender, bytes32 indexed _to, uint256 amount);

    constructor(string memory name, string memory symbol)
        public
        ERC20(name, symbol)
    {}

    function burn(uint256 amount, bytes32 to) public {
        _burn(_msgSender(), amount);

        emit Burn(_msgSender(), to, amount);
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }
}

contract WrappedLuna is WrappedToken {
    constructor() public WrappedToken("Wrapped LUNA Token", "LUNA") {}
}

contract WrappedUST is WrappedToken {
    constructor() public WrappedToken("Wrapped UST Token", "UST") {}
}

contract WrappedKRT is WrappedToken {
    constructor() public WrappedToken("Wrapped KRT Token", "KRT") {}
}

contract WrappedSDT is WrappedToken {
    constructor() public WrappedToken("Wrapped SDT Token", "SDT") {}
}

contract WrappedMNT is WrappedToken {
    constructor() public WrappedToken("Wrapped MNT Token", "MNT") {}
}

contract WrappedMIR is WrappedToken {
    constructor() public WrappedToken("Wrapped MIR Token", "MIR") {}
}

contract WrappedmAAPL is WrappedToken {
    constructor() public WrappedToken("Wrapped Mirror AAPL Token", "mAAPL") {}
}

contract WrappedmGOOGL is WrappedToken {
    constructor() public WrappedToken("Wrapped Mirror GOOGL Token", "mGOOGL") {}
}

contract WrappedmTSLA is WrappedToken {
    constructor() public WrappedToken("Wrapped Mirror TSLA Token", "mTSLA") {}
}

contract WrappedmNFLX is WrappedToken {
    constructor() public WrappedToken("Wrapped Mirror NFLX Token", "mNFLX") {}
}

contract WrappedmQQQ is WrappedToken {
    constructor() public WrappedToken("Wrapped Mirror QQQ Token", "mQQQ") {}
}

contract WrappedmTWTR is WrappedToken {
    constructor() public WrappedToken("Wrapped Mirror TWTR Token", "mTWTR") {}
}

contract WrappedmMSFT is WrappedToken {
    constructor() public WrappedToken("Wrapped Mirror MSFT Token", "mMSFT") {}
}

contract WrappedmAMZN is WrappedToken {
    constructor() public WrappedToken("Wrapped Mirror AMZN Token", "mAMZN") {}
}

contract WrappedmBABA is WrappedToken {
    constructor() public WrappedToken("Wrapped Mirror BABA Token", "mBABA") {}
}

contract WrappedmIAU is WrappedToken {
    constructor() public WrappedToken("Wrapped Mirror IAU Token", "mIAU") {}
}

contract WrappedmSLV is WrappedToken {
    constructor() public WrappedToken("Wrapped Mirror SLV Token", "mSLV") {}
}

contract WrappedmUSO is WrappedToken {
    constructor() public WrappedToken("Wrapped Mirror USO Token", "mUSO") {}
}

contract WrappedmVIXY is WrappedToken {
    constructor() public WrappedToken("Wrapped Mirror VIXY Token", "mVIXY") {}
}

contract WrappedaUST is WrappedToken {
    constructor() public WrappedToken("Wrapped Anchor UST Token", "aUST") {}
}