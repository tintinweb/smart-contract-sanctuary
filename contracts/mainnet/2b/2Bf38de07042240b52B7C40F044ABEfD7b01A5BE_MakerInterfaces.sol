pragma solidity >=0.5.4 <0.7.0;

interface GemLike {
    function balanceOf(address) external view returns (uint);
    function transferFrom(address, address, uint) external returns (bool);
    function approve(address, uint) external returns (bool success);
    function decimals() external view returns (uint);
    function transfer(address,uint) external returns (bool);
}

interface DSTokenLike {
    function mint(address,uint) external;
    function burn(address,uint) external;
}

interface VatLike {
    function can(address, address) external view returns (uint);
    function dai(address) external view returns (uint);
    function hope(address) external;
    function wards(address) external view returns (uint);
    function ilks(bytes32) external view returns (uint Art, uint rate, uint spot, uint line, uint dust);
    function urns(bytes32, address) external view returns (uint ink, uint art);
    function frob(bytes32, address, address, address, int, int) external;
    function slip(bytes32,address,int) external;
    function move(address,address,uint) external;
    function fold(bytes32,address,int) external;
    function suck(address,address,uint256) external;
    function flux(bytes32, address, address, uint) external;
    function fork(bytes32, address, address, int, int) external;
}

interface JoinLike {
    function ilk() external view returns (bytes32);
    function gem() external view returns (GemLike);
    function dai() external view returns (GemLike);
    function join(address, uint) external;
    function exit(address, uint) external;
    function vat() external returns (VatLike);
    function live() external returns (uint);
}

interface ManagerLike {
    function vat() external view returns (address);
    function urns(uint) external view returns (address);
    function open(bytes32, address) external returns (uint);
    function frob(uint, int, int) external;
    function give(uint, address) external;
    function move(uint, address, uint) external;
    function flux(uint, address, uint) external;
    function shift(uint, uint) external;
    function ilks(uint) external view returns (bytes32);
    function owns(uint) external view returns (address);
}

interface ScdMcdMigrationLike {
    function swapSaiToDai(uint) external;
    function swapDaiToSai(uint) external;
    function migrate(bytes32) external returns (uint);
    function saiJoin() external returns (JoinLike);
    function wethJoin() external returns (JoinLike);
    function daiJoin() external returns (JoinLike);
    function cdpManager() external returns (ManagerLike);
    function tub() external returns (SaiTubLike);
}

interface ValueLike {
    function peek() external returns (uint, bool);
}

interface SaiTubLike {
    function skr() external view returns (GemLike);
    function gem() external view returns (GemLike);
    function gov() external view returns (GemLike);
    function sai() external view returns (GemLike);
    function pep() external view returns (ValueLike);
    function bid(uint) external view returns (uint);
    function ink(bytes32) external view returns (uint);
    function tab(bytes32) external returns (uint);
    function rap(bytes32) external returns (uint);
    function shut(bytes32) external;
    function exit(uint) external;
}

interface VoxLike {
    function par() external returns (uint);
}

interface JugLike {
    function drip(bytes32) external;
}

interface PotLike {
    function chi() external view returns (uint);
    function pie(address) external view returns (uint);
    function drip() external;
}