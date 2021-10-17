pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "hardhat/console.sol";

library Library {
    struct WhiteListed {
        bool purchased;
        bool whitelisted;
    }
}

contract CPAN_IDO is Initializable, OwnableUpgradeable,PausableUpgradeable {

    using Library for Library.WhiteListed;

    mapping(address => Library.WhiteListed) private _whitelisted;
    address[] _purchased;

    uint256 private _idoPackage;
    uint256 private _totalRaise;

    address payable public _idoOwner;

    event BuyIDO(address _addr);
    event OwnerWithdraw(uint256 _amount);

    bool private _limitWhitelist;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __Ownable_init();
        __Pausable_init();
        _idoPackage = 0.05 * (10 ** 18);
        _totalRaise = 0.2 * (10 ** 18);
        _idoOwner = payable(msg.sender);
        _limitWhitelist = true;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setWhitelisted(address[] memory _addresses) external onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            _whitelisted[_addresses[i]].whitelisted = true;
        }
    }

    function setWhitelistLimit(bool isLimit) external onlyOwner {
        _limitWhitelist = isLimit;
    }

    function addAddressToWhitelist(address _address) external onlyOwner {
        require(!_whitelisted[_address].whitelisted, "CPAN IDO: address has been whitelisted");
        _whitelisted[_address].whitelisted = true;
    }

    function isAddressWhitelisted(address addr) public view returns(bool) {
        return _whitelisted[addr].whitelisted || !_limitWhitelist;
    }

    function buyIDO() external whenNotPaused payable {
        address _sender = msg.sender;
        uint256 _amount = msg.value;
        require(_sender != address(0), "CPAN IDO: Zero address sender");
        require(!_whitelisted[_sender].purchased, "CPAN IDO: Address has already purchased the package");
        require(_amount == _idoPackage, "CPAN IDO: Invalid package IDO");
        require(getBalance() <= _totalRaise, "CPAN IDO: Total raise reached");
        require(isAddressWhitelisted(_sender), "CPAN IDO: address is not in whitelisted");
        _whitelisted[_sender].purchased = true;
        _purchased.push(_sender);
        emit BuyIDO(_sender);
    }

    function withdraw() external onlyOwner {
        // get the amount of Ether stored in this contract
        uint256 amount = address(this).balance;
        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = _idoOwner.call{value: amount}("");
        require(success, "Failed to send Ether");
        emit OwnerWithdraw(amount);
    }

    function setRaiseLimit(uint256 _limit) external onlyOwner {
        _totalRaise = _limit;
    }

    function setIDOPackage(uint256 _package) external onlyOwner {
        _idoPackage = _package;
    }

    function getTotalRaise() public view returns(uint256) {
        return _totalRaise;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function isPurchased(address addr) public view returns(bool) {
        return _whitelisted[addr].purchased;
    }

    function getAllPurchased() public view returns (address[] memory) {
        return _purchased;
    }

    function fetchData(address addr) public view returns(
        uint256 current,
        uint256 total,
        bool purchased,
        bool whitelisted,
        bool enableWhitelist) {
        return (
            getBalance(),
            getTotalRaise(),
            isPurchased(addr),
            isAddressWhitelisted(addr),
            _limitWhitelist
        );
    }

    function getIDOPackage() public view returns(uint256) {
        return _idoPackage;
    }
}
