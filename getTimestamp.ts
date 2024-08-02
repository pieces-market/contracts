function getUnixTimestamp(year: number, month: number, day: number, hour: number, minute: number, second: number) {
    const date = new Date(year, month - 1, day, hour, minute, second)

    return Math.floor(date.getTime() / 1000)
}

console.log(`Timestamp: ${getUnixTimestamp(2024, 8, 2, 0, 0, 0)}`)
