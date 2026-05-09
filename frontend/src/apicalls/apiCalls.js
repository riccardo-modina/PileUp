import axiosInstance from '../axios';
import { encryptData, decryptData } from '../helpers/crypto';

// Helpers for E2EE
function encryptMovimentoPayload(data) {
    const masterKey = sessionStorage.getItem('masterKey');
    if (!masterKey || !data) return data;
    const encrypted = { ...data };
    if (encrypted.titolo) encrypted.titolo = encryptData(encrypted.titolo, masterKey);
    if (encrypted.descrizione) encrypted.descrizione = encryptData(encrypted.descrizione, masterKey);
    return encrypted;
}

function decryptMovimentoResponse(item) {
    const masterKey = sessionStorage.getItem('masterKey');
    if (!masterKey || !item) return item;
    const decrypted = { ...item };
    if (decrypted.titolo) decrypted.titolo = decryptData(decrypted.titolo, masterKey);
    if (decrypted.descrizione) decrypted.descrizione = decryptData(decrypted.descrizione, masterKey);
    return decrypted;
}

// Generic helper for API requests
function apiRequest(endpoint, method = 'GET', data = null, params = null) {
    const config = {
        url: endpoint,
        method,
    };
    if (data) config.data = data;
    if (params) config.params = params;
    return axiosInstance(config).then(res => res.data);
}

// -------------------- ACCOUNTS --------------------
export function getConti(page = 1, pageSize = 10) {
    return apiRequest('conti/', 'GET', null, { page, page_size: pageSize });
}
export function getConto(id) {
    return apiRequest(`conti/${id}/`, 'GET');
}
export function createConto(data) {
    return apiRequest('conti/', 'POST', data);
}
export function updateConto(id, data) {
    return apiRequest(`conti/${id}/`, 'PATCH', data);
}
export function deleteConto(id) {
    return apiRequest(`conti/${id}/`, 'DELETE');
}

export function getAllConti() {
    return apiRequest('conti/', 'GET', null, { page_size: 'all' });
}

// -------------------- CATEGORIES --------------------
export function getCategorie(page = 1, pageSize = 10) {
    return apiRequest('categorie/', 'GET', null, { page, page_size: pageSize });
}
export function getCategoria(id) {
    return apiRequest(`categorie/${id}/`, 'GET');
}
export function createCategoria(data) {
    return apiRequest('categorie/', 'POST', data);
}
export function updateCategoria(id, data) {
    return apiRequest(`categorie/${id}/`, 'PATCH', data);
}
export function deleteCategoria(id) {
    return apiRequest(`categorie/${id}/`, 'DELETE');
}

export function getAllCategorie() {
    return apiRequest('categorie/', 'GET', null, { page_size: 'all' });
}

// -------------------- MOVEMENTS --------------------
export function getMovimenti(page = 1, pageSize = 10, year = null, month = null, filters = {}) {
    const params = { page, page_size: pageSize, ...filters };
    if (year) params.year = year;
    if (month) params.month = month;

    return apiRequest('movimenti/', 'GET', null, params).then(res => {
        if (res.results) {
            res.results = res.results.map(decryptMovimentoResponse);
        } else if (Array.isArray(res)) {
            res = res.map(decryptMovimentoResponse);
        }
        return res;
    });
}
export function getMovimento(id) {
    return apiRequest(`movimenti/${id}/`, 'GET').then(decryptMovimentoResponse);
}
export function createMovimento(data) {
    const encryptedData = encryptMovimentoPayload(data);
    return apiRequest('movimenti/', 'POST', encryptedData).then(decryptMovimentoResponse);
}
export function updateMovimento(id, data) {
    const encryptedData = encryptMovimentoPayload(data);
    return apiRequest(`movimenti/${id}/`, 'PATCH', encryptedData).then(decryptMovimentoResponse);
}
export function deleteMovimento(id) {
    return apiRequest(`movimenti/${id}/`, 'DELETE');
}

// -------------------- USER (Djoser) --------------------
export function getCurrentUser() {
    return apiRequest('auth/users/me/', 'GET');
}
export function updateCurrentUser(data) {
    return apiRequest('auth/users/me/', 'PATCH', data);
}

// -------------------- AUTHENTICATION & SETTINGS --------------------
export function login(username, password) {
    return apiRequest('auth/jwt/create/', 'POST', { username, password });
}

export function customRegister(data) {
    return apiRequest('auth/register/', 'POST', data);
}

export function getUserProfile() {
    return apiRequest('auth/profile/', 'GET');
}

export function getGlobalSettings() {
    return apiRequest('settings/', 'GET');
}

export function updateRegistrationGlobalSettings(allow_registration) {
    return apiRequest('settings/', 'PATCH', { allow_registration });
}

// -------------------- STATISTICS --------------------
export function getMonthlyStats(year = '2025', month = null) {
    const params = { year };
    if (month) params.month = month;
    return apiRequest('stats/monthly/', 'GET', null, params);
}
export function getMetaChoices() {
    return apiRequest('meta/choices/', 'GET');
}