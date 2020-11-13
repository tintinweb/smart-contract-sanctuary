pragma solidity ^0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC777/IERC777.sol";
import "./PodInterface.sol";

interface MixedPodInterface is IERC777, PodInterface {
}