export interface WhatsappMessage {
  to: string; // Número de teléfono en formato internacional
  body: string;
  mediaUrl?: string;
  mediaType?: 'image' | 'document' | 'audio' | 'video';
}

export interface WhatsappTemplate {
  name: string;
  language: string;
  components?: WhatsappTemplateComponent[];
}

export interface WhatsappTemplateComponent {
  type: 'body' | 'header' | 'button';
  parameters?: WhatsappTemplateParameter[];
}

export interface WhatsappTemplateParameter {
  type: 'text' | 'currency' | 'date_time';
  text?: string;
  currency?: {
    fallback_value: string;
    code: string;
    amount_1000: number;
  };
  date_time?: {
    fallback_value: string;
  };
}

export interface WhatsappResponse {
  success: boolean;
  messageId?: string;
  error?: string;
} 