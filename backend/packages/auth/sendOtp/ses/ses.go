package ses

import (
	"context"
	"fmt"
	"log"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/ses"
	"github.com/aws/aws-sdk-go-v2/service/ses/types"
)

const fromAddress = "no-reply.biblio@samdouble.com"

func SendOtpEmail(ctx context.Context, toEmail, otpCode string, region string) error {
	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion(region))
	if err != nil {
		return fmt.Errorf("load aws config: %w", err)
	}

	client := ses.NewFromConfig(cfg)

	subject := "Your Biblio sign-in code"
	bodyText := fmt.Sprintf("Your sign-in code is: %s\n\nThis code expires in 10 minutes. If you didn't request it, you can ignore this email.", otpCode)
	bodyHTML := fmt.Sprintf("<p>Your sign-in code is: <strong>%s</strong></p><p>This code expires in 10 minutes. If you didn't request it, you can ignore this email.</p>", otpCode)

	input := &ses.SendEmailInput{
		Source: aws.String(fromAddress),
		Destination: &types.Destination{
			ToAddresses: []string{toEmail},
		},
		Message: &types.Message{
			Subject: &types.Content{
				Data:    aws.String(subject),
				Charset: aws.String("UTF-8"),
			},
			Body: &types.Body{
				Text: &types.Content{
					Data:    aws.String(bodyText),
					Charset: aws.String("UTF-8"),
				},
				Html: &types.Content{
					Data:    aws.String(bodyHTML),
					Charset: aws.String("UTF-8"),
				},
			},
		},
	}

	_, err = client.SendEmail(ctx, input)
	if err != nil {
		log.Printf("SES SendEmail: %v", err)
		return err
	}
	return nil
}
