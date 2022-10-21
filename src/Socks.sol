pragma solidity ^0.8.17;

enum Sock {
    Left,
    Right
}

/// @dev Generated from `cast interface 0xdfcCFA821F0bFD9d90746021094FAf6C0f10AB63`
interface Socks {
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event TransferBatch(
        address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] amounts
    );
    event TransferSingle(
        address indexed operator, address indexed from, address indexed to, uint256 id, uint256 amount
    );
    event URI(string value, uint256 indexed id);

    function balanceOf(address, uint256) external view returns (uint256);
    function balanceOfBatch(address[] memory owners, uint256[] memory ids)
        external
        view
        returns (uint256[] memory balances);
    function endTime() external view returns (uint256);
    function isApprovedForAll(address, address) external view returns (bool);
    function mint() external;
    function name() external view returns (string memory);
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
    function setApprovalForAll(address operator, bool approved) external;
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function uri(uint256 id) external pure returns (string memory);
}

