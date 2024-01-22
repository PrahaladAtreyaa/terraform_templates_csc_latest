module.exports = async function (context, req) {
    const status = 200
    const headers = {
        'content-type': 'text/html; charset=utf-8'
    }
    const body = 'Welcome to Azure Function App - NodeJS'

    context.res = {
        status,
        headers,
        body,
    };
}
